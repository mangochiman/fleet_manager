class ReportsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Date range defaults
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    
    # Summary stats for the selected period
    @total_revenue = Sale.where(transaction_date: @start_date..@end_date).sum(:total_amount)
    @total_expenses = Expense.where(expense_date: @start_date..@end_date).sum(:amount)
    @net_profit = @total_revenue - @total_expenses
    @outstanding_amount = Sale.outstanding.where(transaction_date: @start_date..@end_date).sum(:total_amount)
    @outstanding_count = Sale.outstanding.where(transaction_date: @start_date..@end_date).count
    
    # Sales by product - using find_by_sql to avoid GROUP BY issues
    @sales_by_product = Sale.select('product_id, SUM(total_amount) as total')
                            .where(transaction_date: @start_date..@end_date)
                            .group(:product_id)
                            .order('total DESC')
                            .limit(5)
                            .map { |s| [s.product_id, s.total] }
    
    # Expenses by category - using find_by_sql to avoid GROUP BY issues
    @expenses_by_category = Expense.select('category, SUM(amount) as total')
                                   .where(expense_date: @start_date..@end_date)
                                   .group(:category)
                                   .order('total DESC')
                                   .map { |e| [e.category, e.total] }
    
    # Vehicle performance
    @vehicle_performance = Vehicle.all.map do |vehicle|
      {
        name: vehicle.registration_number,
        revenue: vehicle.sales.where(transaction_date: @start_date..@end_date).sum(:total_amount),
        expenses: vehicle.expenses.where(expense_date: @start_date..@end_date).sum(:amount),
        profit: vehicle.sales.where(transaction_date: @start_date..@end_date).sum(:total_amount) - 
                vehicle.expenses.where(expense_date: @start_date..@end_date).sum(:amount)
      }
    end.sort_by { |v| -v[:profit] }
  end
  
  def sales_report
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    
    @sales = Sale.includes(:user, :vehicle, :product)
                .where(transaction_date: @start_date..@end_date)
                .order(transaction_date: :desc)
    
    # Calculate aggregates
    @total_transactions = @sales.count
    @total_revenue = @sales.sum(:total_amount)
    @average_transaction = @total_transactions > 0 ? @total_revenue / @total_transactions : 0
    
    # Status counts - separate queries to avoid GROUP BY issues
    @status_counts = Sale.where(transaction_date: @start_date..@end_date)
                        .group(:payment_status)
                        .count
    
    @status_amounts = Sale.where(transaction_date: @start_date..@end_date)
                          .group(:payment_status)
                          .sum(:total_amount)
    
    respond_to do |format|
      format.html
      format.pdf do
         render pdf: "sales_report_#{Date.current.strftime('%Y%m%d')}",
         template: 'reports/sales_report',
         formats: [:pdf],
         handlers: [:erb],
         layout: 'pdf',
         orientation: 'Landscape',
         page_size: 'A4'
      end

      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=sales_report_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
  
  def expenses_report
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    
    @expenses = Expense.includes(:vehicle, :recorded_by)
                       .where(expense_date: @start_date..@end_date)
                       .order(expense_date: :desc)
    
    @total_expenses = @expenses.sum(:amount)
    @total_transactions = @expenses.count
    
    # Expenses by category - separate query
    @expenses_by_category = Expense.where(expense_date: @start_date..@end_date)
                                   .group(:category)
                                   .sum(:amount)
    
    # Expenses by vehicle
    @expenses_by_vehicle = Expense.where(expense_date: @start_date..@end_date)
                                  .group(:vehicle_id)
                                  .sum(:amount)
                                  .sort_by { |_, amount| -amount }
                                  .first(5)
    
    respond_to do |format|
      format.html
      format.pdf do
         render pdf: "expenses_report_#{Date.current.strftime('%Y%m%d')}",
         template: 'reports/expenses_report',
         formats: [:pdf],
         handlers: [:erb],
         layout: 'pdf',
         orientation: 'Landscape',
         page_size: 'A4'
      end

      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=expenses_report_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
  
  def profit_loss_report
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month
    
    # Get all months in range
    @months = (@start_date..@end_date).map { |d| d.strftime('%Y-%m') }.uniq
    
    # Revenue by month using raw SQL
    @revenue_by_month = {}
    @months.each do |month|
      year, month_num = month.split('-')
      start_date = Date.new(year.to_i, month_num.to_i, 1)
      end_date = start_date.end_of_month
      @revenue_by_month[month] = Sale.where(transaction_date: start_date..end_date).sum(:total_amount)
    end
    
    # Expenses by month using raw SQL
    @expenses_by_month = {}
    @months.each do |month|
      year, month_num = month.split('-')
      start_date = Date.new(year.to_i, month_num.to_i, 1)
      end_date = start_date.end_of_month
      @expenses_by_month[month] = Expense.where(expense_date: start_date..end_date).sum(:amount)
    end
    
    # Calculate profit by month
    @profit_by_month = {}
    @months.each do |month|
      @profit_by_month[month] = (@revenue_by_month[month] || 0) - (@expenses_by_month[month] || 0)
    end
    
    # Totals
    @total_revenue = @revenue_by_month.values.sum
    @total_expenses = @expenses_by_month.values.sum
    @net_profit = @total_revenue - @total_expenses
    
    respond_to do |format|
      format.html
      format.pdf do
         render pdf: "profit_loss_report_#{Date.current.strftime('%Y%m%d')}",
         template: 'reports/profit_loss_report',
         formats: [:pdf],
         handlers: [:erb],
         layout: 'pdf',
         orientation: 'Landscape',
         page_size: 'A4'
      end

      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=profit_loss_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
  
  def outstanding_report
    @sales = Sale.outstanding.includes(:user, :vehicle, :product)
                 .order(transaction_date: :asc)
    
    @total_outstanding = @sales.sum(:total_amount)
    @total_customers = @sales.select(:customer_name).distinct.count
    
    @aging_summary = {
      '0-30 days' => @sales.where('transaction_date >= ?', 30.days.ago).sum(:total_amount),
      '31-60 days' => @sales.where(transaction_date: 60.days.ago...30.days.ago).sum(:total_amount),
      '61-90 days' => @sales.where(transaction_date: 90.days.ago...60.days.ago).sum(:total_amount),
      '90+ days' => @sales.where('transaction_date <= ?', 90.days.ago).sum(:total_amount)
    }
    
    respond_to do |format|
      format.html
      format.pdf do
         render pdf: "outstanding_report_#{Date.current.strftime('%Y%m%d')}",
         template: 'reports/outstanding_report',
         formats: [:pdf],
         handlers: [:erb],
         layout: 'pdf',
         orientation: 'Landscape',
         page_size: 'A4'
      end

      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=outstanding_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
end