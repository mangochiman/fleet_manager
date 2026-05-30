class DashboardController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Summary stats
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
    
    # Vehicle performance
    @vehicle_performance = Vehicle.all.map do |vehicle|
      {
        name: vehicle.display_name,
        sales: vehicle.total_sales,
        expenses: vehicle.total_expenses,
        profit: vehicle.profit
      }
    end
    
    # Aging analysis
    today = Date.current
    @aging_data = [
      Sale.outstanding.where('transaction_date >= ?', today - 30.days).sum(:total_amount),
      Sale.outstanding.where(transaction_date: (today - 60.days)...(today - 30.days)).sum(:total_amount),
      Sale.outstanding.where(transaction_date: (today - 90.days)...(today - 60.days)).sum(:total_amount),
      Sale.outstanding.where('transaction_date <= ?', today - 90.days).sum(:total_amount)
    ]
  end
end