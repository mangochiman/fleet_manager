class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy, :receipt]
  
  # Role restrictions
  before_action :authorize_admin!, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    # Role-based filtering
    if current_user.driver?
      # Drivers can only see expenses for their assigned vehicle
      if current_user.vehicle_id.present?
        @expenses = Expense.where(vehicle_id: current_user.vehicle_id)
      else
        @expenses = Expense.none
        redirect_to dashboard_path, alert: 'No vehicle assigned to your account.' and return
      end
    else
      # Admins, Managers, Super Admins see all expenses
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
    @total_expenses = @expenses.sum(:amount)
    @expenses_by_category = @expenses.group(:category).sum(:amount)
    
    # Vehicles for filter (only show vehicles the user has access to)
    if current_user.driver?
      @vehicles = Vehicle.where(id: current_user.vehicle_id)
    else
      @vehicles = Vehicle.active
    end
  end
  
  def show
    # Drivers can only view expenses for their assigned vehicle
    if current_user.driver? && @expense.vehicle_id != current_user.vehicle_id
      redirect_to expenses_path, alert: 'You can only view expenses for your assigned vehicle.'
    end
  end
  
  def new
    authorize_admin!
    @expense = Expense.new
    
    # Drivers cannot create expenses
    if current_user.driver?
      redirect_to expenses_path, alert: 'Drivers cannot create expenses.'
      return
    end
    
    @vehicles = Vehicle.active
  end
  
  def create
    authorize_admin!
    
    # Drivers cannot create expenses
    if current_user.driver?
      redirect_to expenses_path, alert: 'Drivers cannot create expenses.'
      return
    end
    
    @expense = Expense.new(expense_params)
    @expense.recorded_by_id = current_user.id
    
    if @expense.save
      # Attach receipt if uploaded
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
    
    # Drivers cannot edit expenses
    if current_user.driver?
      redirect_to expenses_path, alert: 'Drivers cannot edit expenses.'
      return
    end
    
    @vehicles = Vehicle.active
  end
  
  def update
    authorize_admin!
    
    # Drivers cannot update expenses
    if current_user.driver?
      redirect_to expenses_path, alert: 'Drivers cannot update expenses.'
      return
    end
    
    if @expense.update(expense_params)
      # Handle receipt update
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
    
    # Drivers cannot delete expenses
    if current_user.driver?
      redirect_to expenses_path, alert: 'Drivers cannot delete expenses.'
      return
    end
    
    @expense.destroy
    redirect_to expenses_path, notice: 'Expense was successfully deleted.'
  end
  
  def receipt
    # Drivers can only view receipts for their assigned vehicle
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
    params.require(:expense).permit(:vehicle_id, :category, :amount, :expense_date, :description, :receipt)
  end
end