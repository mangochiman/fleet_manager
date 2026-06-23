# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_drivers, only: [:index]
  
  def index
    # Admins, Managers, Super Admins see full dashboard
    @total_revenue = Sale.sum(:total_amount)
    @total_expenses = Expense.sum(:amount)
    @net_profit = @total_revenue - @total_expenses
    
    # Sales Status Breakdown
    @outstanding_amount = Sale.outstanding.sum(:total_amount)
    @outstanding_count = Sale.outstanding.count
    
    @partial_amount = Sale.partial.sum(:total_amount)
    @partial_count = Sale.partial.count
    
    @paid_amount = Sale.paid.sum(:total_amount)
    @paid_count = Sale.paid.count
    
    @banked_amount = Sale.banked.sum(:total_amount)
    @banked_count = Sale.banked.count
    
    # Recent data
    @recent_sales = Sale.includes(:user, :vehicle, :product).order(created_at: :desc).limit(10)
    @recent_expenses = Expense.includes(:vehicle).order(created_at: :desc).limit(5)
    
    # Chart data - Last 6 months
    @months = []
    @revenues = []
    @expenses_chart = []
    
    6.downto(0).each do |i|
      month = i.months.ago
      @months << month.strftime("%b %Y")
      @revenues << Sale.where(transaction_date: month.beginning_of_month..month.end_of_month).sum(:total_amount)
      @expenses_chart << Expense.where(expense_date: month.beginning_of_month..month.end_of_month).sum(:amount)
    end
    
    # Vehicle performance for all vehicles
    @vehicle_performance = Vehicle.all.map do |vehicle|
      {
        name: vehicle.display_name,
        sales: vehicle.total_sales,
        expenses: vehicle.total_expenses,
        profit: vehicle.profit
      }
    end
    
    # Expense Breakdown by Category
    expense_categories = Expense.group(:category).sum(:amount).sort_by { |_, amount| -amount }
    @expense_category_labels = expense_categories.map { |category, _| category.titleize }
    @expense_category_data = expense_categories.map { |_, amount| amount.to_f }
    @expense_category_colors = ['#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4', '#6366f1']
    
    # If no expenses, show placeholder
    if @expense_category_labels.empty?
      @expense_category_labels = ['No Data Available']
      @expense_category_data = [1]
    end
  end
  
  private
  
  def redirect_drivers
    if current_user.driver?
      redirect_to sales_path, alert: 'Access denied. Drivers can only access their trips.'
    end
  end
end