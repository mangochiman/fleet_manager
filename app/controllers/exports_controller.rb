require 'csv'
class ExportsController < ApplicationController
  before_action :authenticate_user!
  
  def sales
    @sales = Sale.includes(:user, :vehicle, :product)
                 .order(created_at: :desc)
    
    # Apply filters if present
    if params[:search].present?
      @sales = @sales.where("customer_name LIKE ? OR transaction_id LIKE ?", 
                            "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    if params[:status].present?
      @sales = @sales.where(payment_status: params[:status])
    end
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=sales_export_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
      format.csv do
        send_data generate_csv, filename: "sales_export_#{Date.current.strftime('%Y%m%d')}.csv"
      end
    end
  end
  
  def expenses
    @expenses = Expense.includes(:vehicle, :recorded_by)
                       .order(expense_date: :desc)
    
    if params[:vehicle_id].present?
      @expenses = @expenses.where(vehicle_id: params[:vehicle_id])
    end
    
    if params[:category].present?
      @expenses = @expenses.where(category: params[:category])
    end
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=expenses_export_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
  
  def outstanding
    @sales = Sale.outstanding.includes(:user, :vehicle, :product)
                 .order(transaction_date: :asc)
    
    respond_to do |format|
      format.xlsx do
        response.headers['Content-Disposition'] = "attachment; filename=outstanding_export_#{Date.current.strftime('%Y%m%d')}.xlsx"
      end
    end
  end
  
  private
  
  def generate_csv
    CSV.generate(headers: true) do |csv|
      # Add headers
      csv << ["Transaction ID", "Date", "Customer Name", "Customer Phone", "Product", 
              "Quantity", "Unit", "Unit Price", "Total Amount", "Payment Status", "Vehicle"]
      
      # Add data
      @sales.each do |sale|
        csv << [
          sale.transaction_id,
          sale.transaction_date.strftime("%Y-%m-%d"),
          sale.customer_name,
          sale.customer_phone,
          sale.product.name,
          sale.quantity,
          sale.product.unit,
          sale.unit_price,
          sale.total_amount,
          sale.payment_status.titleize,
          sale.vehicle.registration_number
        ]
      end
    end
  end
end
