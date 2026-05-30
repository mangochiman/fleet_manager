class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy, :toggle_status]
  
  def index
    @products = Product.all.order(:name)
    
    # Apply filters
    if params[:status].present?
      case params[:status]
      when 'active'
        @products = @products.active
      when 'inactive'
        @products = @products.inactive
      end
    end
    
    if params[:search].present?
      @products = @products.where("name LIKE ? OR description LIKE ?", 
                                  "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Pagination
    @per_page = (params[:per_page] || 10).to_i
    @per_page = 50 if @per_page > 50
    @products = @products.paginate(page: params[:page], per_page: @per_page)
    
    # Stats (using direct SQL queries, not methods)
    @total_products = Product.count
    @active_products = Product.active.count
    @inactive_products = Product.inactive.count
    
    # Calculate total revenue from sales table, not Product model method
    @total_revenue = Sale.sum(:total_amount)
  end
  
  def show
    @recent_sales = @product.sales.includes(:user, :vehicle).order(created_at: :desc).limit(5)
  end
  
  def new
    @product = Product.new
  end
  
  def create
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    # Check if product has associated sales
    if @product.sales.exists?
      redirect_to products_path, alert: 'Cannot delete product with associated sales. Consider deactivating instead.'
    else
      @product.destroy
      redirect_to products_path, notice: 'Product was successfully deleted.'
    end
  end
  
  def toggle_status
    @product.toggle_status!
    redirect_to products_path, notice: "Product is now #{@product.active? ? 'active' : 'inactive'}."
  end
  
  private
  
  def set_product
    @product = Product.find(params[:id])
  end
  
  def product_params
    params.require(:product).permit(:name, :description, :price, :unit, :active)
  end
end