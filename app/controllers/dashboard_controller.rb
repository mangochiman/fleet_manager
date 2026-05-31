class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Role-based dashboard data
    if current_user.driver?
      # Drivers see only their own data
      @recent_sales = current_user.sales.includes(:product).order(created_at: :desc).limit(10)
      @total_revenue = current_user.sales.sum(:total_amount)
      @outstanding_amount = current_user.sales.outstanding.sum(:total_amount)
      @outstanding_count = current_user.sales.outstanding.count
      
      # Drivers don't see expenses, profit, or other vehicles
      @total_expenses = 0
      @net_profit = 0
      @recent_expenses = []
      
      # Vehicle performance for driver's assigned vehicle only
      if current_user.vehicle_id.present?
        assigned_vehicle = Vehicle.find_by(id: current_user.vehicle_id)
        if assigned_vehicle
          @vehicle_performance = [{
            name: assigned_vehicle.display_name,
            sales: assigned_vehicle.total_sales,
            expenses: assigned_vehicle.total_expenses,
            profit: assigned_vehicle.profit
          }]
        else
          @vehicle_performance = []
        end
      else
        @vehicle_performance = []
      end
      
      # Chart data limited to driver's sales
      @months = []
      @revenues = []
      @expenses_chart = []
      
      6.downto(0).each do |i|
        month = i.months.ago
        @months << month.strftime("%b %Y")
        @revenues << current_user.sales.where(transaction_date: month.beginning_of_month..month.end_of_month).sum(:total_amount)
        @expenses_chart << 0 # Drivers don't see expenses chart
      end
      
      # Expense breakdown - drivers see empty chart
      @expense_category_labels = ['No Data Available']
      @expense_category_data = [1]
      
    else
      # Admins, Managers, Super Admins see full dashboard
      @total_revenue = Sale.sum(:total_amount)
      @total_expenses = Expense.sum(:amount)
      @net_profit = @total_revenue - @total_expenses
      @outstanding_amount = Sale.outstanding.sum(:total_amount)
      @outstanding_count = Sale.outstanding.count
      
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
  end
end