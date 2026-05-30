class ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_expense, only: [:show, :edit, :update, :destroy]
  
  def index
    @expenses = Expense.includes(:vehicle, :recorded_by).order(expense_date: :desc)
    
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
    @expenses_by_category = Expense.group(:category).sum(:amount)
    @vehicles = Vehicle.active
  end
  
  def show
  end
  
  def new
    @expense = Expense.new
    @vehicles = Vehicle.active
  end
  
  def create
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
    @vehicles = Vehicle.active
  end
  
  def update
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
    @expense.destroy
    redirect_to expenses_path, notice: 'Expense was successfully deleted.'
  end
  
  def receipt
    @expense = Expense.find(params[:id])
    if @expense.receipt.attached?
      redirect_to url_for(@expense.receipt)
    else
      redirect_to @expense, alert: 'No receipt attached to this expense.'
    end
  end
  
  private
  
  def set_expense
    @expense = Expense.find(params[:id])
  end
  
  def expense_params
    params.require(:expense).permit(:vehicle_id, :category, :amount, :expense_date, :description, :receipt)
  end
end