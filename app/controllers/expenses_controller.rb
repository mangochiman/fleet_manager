# app/controllers/expenses_controller.rb
class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy, :receipt, 
                                      :mark_paid, :mark_pending, :cancel]
  
  before_action :authorize_admin!, except: [:index, :show, :receipt]
  
  def index
    # Role-based filtering
    if current_user.driver?
      if current_user.vehicle_id.present?
        @expenses = Expense.where(vehicle_id: current_user.vehicle_id)
      else
        @expenses = Expense.none
        redirect_to dashboard_path, alert: 'No vehicle assigned to your account.' and return
      end
    else
      @expenses = Expense.all
    end
    
    @expenses = @expenses.includes(:vehicle, :recorded_by).order(expense_date: :desc)
    
    # Apply filters
    if params[:vehicle_id].present?
      @expenses = @expenses.where(vehicle_id: params[:vehicle_id])
    end
    
    if params[:category].present?
      @expenses = @expenses.where(category: params[:category])
    end
    
    if params[:payment_mode].present?
      @expenses = @expenses.where(payment_mode: params[:payment_mode])
    end
    
    if params[:payment_status].present?
      @expenses = @expenses.where(payment_status: params[:payment_status])
    end
    
    if params[:start_date].present?
      @expenses = @expenses.where("expense_date >= ?", params[:start_date])
    end
    
    if params[:end_date].present?
      @expenses = @expenses.where("expense_date <= ?", params[:end_date])
    end
    
    # Pagination
    @per_page = (params[:per_page] || 20).to_i
    @per_page = 100 if @per_page > 100
    @expenses = @expenses.paginate(page: params[:page], per_page: @per_page)
    
    # Stats
    if current_user.driver?
      @total_expenses = @expenses.sum(:amount)
      @pending_expenses = @expenses.pending.sum(:amount)
      @paid_expenses = @expenses.paid.sum(:amount)
      @cancelled_expenses = @expenses.cancelled.sum(:amount)
    else
      @total_expenses = @expenses.sum(:amount)
      @pending_expenses = @expenses.pending.sum(:amount)
      @paid_expenses = @expenses.paid.sum(:amount)
      @cancelled_expenses = @expenses.cancelled.sum(:amount)
      
      @expenses_by_category = Expense.where(expense_date: params[:start_date]..params[:end_date])
                                     .group(:category)
                                     .sum(:amount)
    end
    
    @vehicles = current_user.driver? ? Vehicle.where(id: current_user.vehicle_id) : Vehicle.active
  end
  
  def show
    if current_user.driver? && @expense.vehicle_id != current_user.vehicle_id
      redirect_to expenses_path, alert: 'You can only view expenses for your assigned vehicle.'
    end
  end
  
  def new
    authorize_admin!
    @expense = Expense.new
    @vehicles = Vehicle.active
  end
  
  def create
    authorize_admin!
    @expense = Expense.new(expense_params)
    @expense.recorded_by_id = current_user.id
    
    if @expense.save
      if params[:expense][:receipt].present?
        @expense.receipt.attach(params[:expense][:receipt])
      end
      redirect_to @expense, notice: 'Expense was successfully recorded.'
    else
      @vehicles = Vehicle.active
      render :new
    end
  end
  
  def edit
    authorize_admin!
    unless @expense.editable?
      redirect_to @expense, alert: 'Only pending expenses can be edited.'
      return
    end
    @vehicles = Vehicle.active
  end
  
  def update
    authorize_admin!
    unless @expense.editable?
      redirect_to @expense, alert: 'Only pending expenses can be updated.'
      return
    end
    
    if @expense.update(expense_params)
      if params[:expense][:receipt].present?
        @expense.receipt.attach(params[:expense][:receipt])
      end
      redirect_to @expense, notice: 'Expense was successfully updated.'
    else
      @vehicles = Vehicle.active
      render :edit
    end
  end
  
  def destroy
    authorize_admin!
    unless @expense.editable?
      redirect_to @expense, alert: 'Only pending expenses can be deleted.'
      return
    end
    
    @expense.destroy
    redirect_to expenses_path, notice: 'Expense was successfully deleted.'
  end
  
  def mark_paid
    authorize_admin!
    
    if @expense.paid?
      redirect_to @expense, alert: 'This expense is already marked as paid.'
      return
    end
    
    if @expense.mark_as_paid!(
      reference: params[:payment_reference],
      updated_by: current_user
    )
      redirect_to @expense, notice: 'Expense marked as paid successfully.'
    else
      redirect_to @expense, alert: 'Unable to mark expense as paid.'
    end
  end
  
  def mark_pending
    authorize_admin!
    
    if @expense.pending?
      redirect_to @expense, alert: 'This expense is already pending.'
      return
    end
    
    if @expense.mark_as_pending!(updated_by: current_user)
      redirect_to @expense, notice: 'Expense marked as pending successfully.'
    else
      redirect_to @expense, alert: 'Unable to mark expense as pending.'
    end
  end
  
  def cancel
    authorize_admin!
    
    if @expense.cancelled?
      redirect_to @expense, alert: 'This expense is already cancelled.'
      return
    end
    
    if @expense.cancel!(updated_by: current_user)
      redirect_to @expense, notice: 'Expense cancelled successfully.'
    else
      redirect_to @expense, alert: 'Unable to cancel expense.'
    end
  end
  
  def receipt
    if current_user.driver? && @expense.vehicle_id != current_user.vehicle_id
      redirect_to expenses_path, alert: 'You can only view receipts for your assigned vehicle.'
      return
    end
    
    if @expense.receipt.attached?
      redirect_to url_for(@expense.receipt)
    else
      redirect_to @expense, alert: 'No receipt attached to this expense.'
    end
  end
  
  private
  
  def set_expense
    @expense = Expense.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to expenses_path, alert: 'Expense not found.'
  end
  
  def expense_params
    params.require(:expense).permit(:vehicle_id, :category, :payment_mode, :payment_status,
                                    :amount, :expense_date, :description, :receipt)
  end
end