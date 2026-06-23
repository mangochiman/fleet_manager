# app/controllers/sales_controller.rb
class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sale, only: [:show, :edit, :update, :destroy, :mark_paid, :mark_banked, :mark_paid_form, :record_payment_form, :record_payment, :proof]
  
  # Role restrictions
  before_action :authorize_admin!, only: [:edit, :update, :destroy, :mark_paid, :mark_banked]
  
  def index
    # Set per_page from params or default to 20
    @per_page = (params[:per_page] || 20).to_i
    @per_page = 100 if @per_page > 100 # Max limit
    
    # Role-based filtering
    if current_user.driver?
      # Drivers can only see their own sales
      sales_scope = Sale.where(user_id: current_user.id)
      
      # Get trip metrics - Only trips, no financial data
      @total_trips = sales_scope.sum(:quantity)  # Total quantity = total trips
      @sales_total_count = sales_scope.count
      
      # Calculate monthly trips
      start_of_month = Date.current.beginning_of_month
      end_of_month = Date.current.end_of_month
      @monthly_trips = sales_scope.where(transaction_date: start_of_month..end_of_month).count
      
      # Apply search filter if present
      if params[:search].present?
        sales_scope = sales_scope.where("customer_name LIKE ?", "%#{params[:search]}%")
      end
      
      # Apply pagination
      @sales = sales_scope.includes(:user, :vehicle, :product)
                          .order(created_at: :desc)
                          .paginate(page: params[:page], per_page: @per_page)
      
      # Render driver-specific view
      render :driver_index and return
    else
      # Admins, Managers, Super Admins see all sales
      @sales = Sale.all
    end
    
    # Start with base query for non-drivers
    @sales = @sales.includes(:user, :vehicle, :product)
                  .order(created_at: :desc)
                  .paginate(page: params[:page], per_page: @per_page)
    
    # Apply search filter if present
    if params[:search].present?
      @sales = @sales.where("customer_name LIKE ? OR transaction_id LIKE ?", 
                            "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Apply status filter if present
    if params[:status].present?
      @sales = @sales.where(payment_status: params[:status])
    end
    
    # Stats (using correct logic for each status)
    @total_sales = @sales.sum(:total_amount)
    
    # Outstanding: Show remaining balance (what's still owed)
    @outstanding_sales = @sales.outstanding.sum("total_amount - COALESCE(paid_amount, 0)")
    
    # Partial: Show remaining balance (what's still owed)
    @partial_sales = @sales.partial.sum("total_amount - COALESCE(paid_amount, 0)")
    
    # Paid: Show total amount paid (what was collected)
    @paid_sales = @sales.paid.sum(:paid_amount)
  end
  
  def show
    @payment_histories = @sale.payment_histories.order(created_at: :desc)
    
    # Drivers can only view their own sales
    if current_user.driver? && @sale.user_id != current_user.id
      redirect_to sales_path, alert: 'You can only view your own sales.'
    end
  end
  
  def new
    @sale = Sale.new
    @products = Product.active.order(:name)
    
    # Role-based vehicle selection
    if current_user.driver?
      # Drivers can only select their assigned vehicle
      @vehicles = Vehicle.where(id: current_user.vehicle_id).active
      render :driver_new and return  # Use driver-specific form
    else
      @vehicles = Vehicle.active.order(:registration_number)
    end
  end
  
  def create
    @sale = Sale.new(sale_params)
    @sale.user_id = current_user.id
    
    # Drivers can only create sales for their assigned vehicle
    if current_user.driver?
      @sale.vehicle_id = current_user.vehicle_id
    end
    
    # Get product and set prices
    if params[:sale][:product_id].present?
      product = Product.find(params[:sale][:product_id])
      @sale.unit_price = product.price
      @sale.price_at_sale = product.price  # Store the price at sale
    end
    
    # Auto-calculate total amount
    if params[:sale][:quantity].present?
      @sale.total_amount = params[:sale][:quantity].to_f * @sale.unit_price
    end
    
    if @sale.save
      # Redirect based on user role
      if current_user.driver?
        redirect_to sales_path, notice: 'Trip was successfully recorded.'
      else
        redirect_to @sale, notice: 'Sale was successfully created.'
      end
    else
      @products = Product.active.order(:name)
      if current_user.driver?
        @vehicles = Vehicle.where(id: current_user.vehicle_id).active
        render :driver_new
      else
        @vehicles = Vehicle.active.order(:registration_number)
        render :new
      end
    end
  end
  
  def edit
    # Check if sale can be edited
    unless @sale.editable?
      redirect_to @sale, alert: 'This sale cannot be edited because it has been paid or banked.'
      return
    end
    
    @products = Product.active.order(:name)
    
    if current_user.driver?
      @vehicles = Vehicle.where(id: current_user.vehicle_id).active
    else
      @vehicles = Vehicle.active.order(:registration_number)
    end
    
    # Check authorization
    if current_user.driver? && @sale.user_id != current_user.id
      redirect_to sales_path, alert: 'You can only edit your own sales.'
    end
  end
  
  def update
    # Check if sale can be edited
    unless @sale.editable?
      redirect_to @sale, alert: 'This sale cannot be updated because it has been paid or banked.'
      return
    end
    
    # Check authorization
    if current_user.driver? && @sale.user_id != current_user.id
      redirect_to sales_path, alert: 'You can only update your own sales.'
      return
    end
    
    # IMPORTANT: Handle product change and preserve price_at_sale
    if params[:sale][:product_id].present? && params[:sale][:product_id] != @sale.product_id.to_s
      # If product changed, use the new product's price
      product = Product.find(params[:sale][:product_id])
      params[:sale][:unit_price] = product.price
      params[:sale][:price_at_sale] = product.price
    else
      # Keep the original price_at_sale
      params[:sale][:unit_price] = @sale.price_at_sale
      params[:sale][:price_at_sale] = @sale.price_at_sale
    end
    
    # Recalculate total amount based on quantity and stored price
    if params[:sale][:quantity].present?
      params[:sale][:total_amount] = params[:sale][:quantity].to_f * params[:sale][:price_at_sale].to_f
    end
    
    if @sale.update(sale_params)
      redirect_to @sale, notice: 'Sale was successfully updated.'
    else
      @products = Product.active.order(:name)
      if current_user.driver?
        @vehicles = Vehicle.where(id: current_user.vehicle_id).active
      else
        @vehicles = Vehicle.active.order(:registration_number)
      end
      render :edit
    end
  end
  
  def destroy
    # Check authorization
    if current_user.driver?
      redirect_to sales_path, alert: 'Drivers cannot delete sales.'
      return
    end
    
    # Check if sale can be deleted
    unless @sale.editable?
      redirect_to @sale, alert: 'This sale cannot be deleted because it has been paid or banked.'
      return
    end
    
    @sale.destroy
    redirect_to sales_path, notice: 'Sale was successfully deleted.'
  end
  
  def mark_paid_form
    # Only admins and managers can mark payments
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to @sale, alert: 'You are not authorized to mark payments.'
    end
  end
  
  def mark_paid
    @sale = Sale.find(params[:id])
    
    # Only admins and managers can mark payments
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to @sale, alert: 'You are not authorized to mark payments.'
      return
    end
    
    proof_image = nil
    if params[:proof_image].present?
      proof_image = params[:proof_image].original_filename
    end
    
    if @sale.mark_as_paid!(
      proof_number: params[:proof_number],
      proof_image: proof_image,
      notes: params[:notes],
      updated_by: current_user
    )
      # Attach the file to the payment history record
      if params[:proof_image].present?
        payment_history = @sale.payment_histories.last
        payment_history.proof_attachment.attach(params[:proof_image])
      end
      
      redirect_to @sale, notice: 'Full payment marked as paid successfully.'
    else
      redirect_to @sale, alert: 'Unable to mark payment as paid.'
    end
  end
  
  def mark_banked
    # Only admins and managers can mark banked
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to @sale, alert: 'You are not authorized to mark payments as banked.'
      return
    end
    
    if @sale.mark_as_banked!(notes: params[:notes], updated_by: current_user)
      redirect_to @sale, notice: 'Payment marked as banked successfully.'
    else
      redirect_to @sale, alert: 'Unable to mark payment as banked.'
    end
  end
  
  def record_payment_form
    # Only admins and managers can record payments
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to @sale, alert: 'You are not authorized to record payments.'
    end
  end
  
  def record_payment
    @sale = Sale.find(params[:id])
    
    # Only admins and managers can record payments
    unless current_user.admin? || current_user.manager? || current_user.super_admin?
      redirect_to @sale, alert: 'You are not authorized to record payments.'
      return
    end
    
    amount = params[:payment_amount].to_f
    
    if amount <= 0
      redirect_to @sale, alert: 'Payment amount must be greater than 0.'
      return
    end
    
    if amount > @sale.remaining_balance
      redirect_to @sale, alert: "Payment amount cannot exceed remaining balance of #{helpers.number_to_currency(@sale.remaining_balance)}."
      return
    end
    
    proof_image = nil
    if params[:proof_image].present?
      proof_image = params[:proof_image].original_filename
    end
    
    if @sale.record_payment!(
      amount: amount,
      reference_number: params[:reference_number],
      proof_image: proof_image,
      notes: params[:notes],
      updated_by: current_user
    )
      # Attach the file to the payment history record
      if params[:proof_image].present?
        payment_history = @sale.payment_histories.last
        payment_history.proof_attachment.attach(params[:proof_image])
      end
      
      if @sale.paid?
        redirect_to @sale, notice: "Full payment of #{helpers.number_to_currency(amount)} recorded successfully!"
      else
        redirect_to @sale, notice: "Partial payment of #{helpers.number_to_currency(amount)} recorded. Remaining balance: #{helpers.number_to_currency(@sale.remaining_balance)}"
      end
    else
      redirect_to @sale, alert: 'Unable to record payment.'
    end
  end
  
  def proof
    @sale = Sale.find(params[:id])
    
    # Drivers can only view proof of their own sales
    if current_user.driver? && @sale.user_id != current_user.id
      redirect_to sales_path, alert: 'You can only view proof for your own sales.'
      return
    end
    
    @payment_history = if params[:history_id].present?
      @sale.payment_histories.find(params[:history_id])
    else
      @sale.payment_histories.where(new_status: 'paid').order(created_at: :desc).first
    end
    
    unless @payment_history&.proof_attachment&.attached?
      redirect_to @sale, alert: 'No proof of payment available for this transaction.'
    end
  end
  
  private
  
  def set_sale
    @sale = Sale.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to sales_path, alert: 'Sale not found.'
  end
  
  def sale_params
    params.require(:sale).permit(:product_id, :vehicle_id, :customer_name, :customer_phone, 
                                  :quantity, :unit_price, :price_at_sale, :total_amount, 
                                  :transaction_date, :notes)
  end
end