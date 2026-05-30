class SalesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_sale, only: [:show, :edit, :update, :destroy, :mark_paid, :mark_banked, :mark_paid_form, :record_payment_form, :record_payment, :proof]
  
  def index
    # Set per_page from params or default to 20
    @per_page = (params[:per_page] || 20).to_i
    @per_page = 100 if @per_page > 100 # Max limit
    
    # Start with base query
    @sales = Sale.includes(:user, :vehicle, :product)
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
    
    # Stats (unfiltered totals)
    @total_sales = Sale.sum(:total_amount)
    @outstanding_sales = Sale.outstanding.sum(:total_amount)
    @partial_sales = Sale.partial.sum(:total_amount)
    @paid_sales = Sale.paid.sum(:total_amount)
  end
  
  def show
    @payment_histories = @sale.payment_histories.order(created_at: :desc)
  end
  
  def new
    @sale = Sale.new
    @products = Product.active
    @vehicles = Vehicle.active
  end
  
  def create
    @sale = Sale.new(sale_params)
    @sale.user_id = current_user.id
    
    # Get product price and set unit_price (auto-populated, read-only)
    if params[:sale][:product_id].present?
      product = Product.find(params[:sale][:product_id])
      @sale.unit_price = product.price
    end
    
    # Auto-calculate total amount
    if params[:sale][:quantity].present?
      @sale.total_amount = params[:sale][:quantity].to_f * @sale.unit_price
    end
    
    if @sale.save
      redirect_to @sale, notice: 'Sale was successfully created.'
    else
      @products = Product.active
      @vehicles = Vehicle.active
      render :new
    end
  end
  
  def edit
    @products = Product.active
    @vehicles = Vehicle.active
  end
  
  def update
    # Get product price if product changed
    if params[:sale][:product_id].present? && params[:sale][:product_id] != @sale.product_id.to_s
      product = Product.find(params[:sale][:product_id])
      @sale.unit_price = product.price
    end
    
    # Recalculate total amount
    if params[:sale][:quantity].present?
      params[:sale][:total_amount] = params[:sale][:quantity].to_f * @sale.unit_price
    end
    
    if @sale.update(sale_params)
      redirect_to @sale, notice: 'Sale was successfully updated.'
    else
      @products = Product.active
      @vehicles = Vehicle.active
      render :edit
    end
  end
  
  def destroy
    @sale.destroy
    redirect_to sales_path, notice: 'Sale was successfully deleted.'
  end
  
  def mark_paid_form
    # Render the form to collect payment proof for full payment
  end
  
  def mark_paid
    @sale = Sale.find(params[:id])
    
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
    if @sale.mark_as_banked!(notes: params[:notes], updated_by: current_user)
      redirect_to @sale, notice: 'Payment marked as banked successfully.'
    else
      redirect_to @sale, alert: 'Unable to mark payment as banked.'
    end
  end
  
  def record_payment_form
    # Render the form to record partial payment
  end
  
  def record_payment
    @sale = Sale.find(params[:id])
    
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
  end
  
  def sale_params
    params.require(:sale).permit(:product_id, :vehicle_id, :customer_name, :customer_phone, 
                                  :quantity, :unit_price, :transaction_date, :notes)
  end
end