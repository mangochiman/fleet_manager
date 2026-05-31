class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy, :toggle_status]
  
  # Role restrictions
  before_action :authorize_admin!, only: [:new, :create, :edit, :update, :destroy, :toggle_status]
  
  def index
    # Role-based filtering - everyone can see products but with limitations
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
    # Everyone can view product details
    @recent_sales = @product.sales.includes(:user, :vehicle).order(created_at: :desc).limit(5)
  end
  
  def new
    authorize_admin!
    
    # Drivers cannot create products
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot create products.'
      return
    end
    
    @product = Product.new
  end
  
  def create
    authorize_admin!
    
    # Drivers cannot create products
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot create products.'
      return
    end
    
    @product = Product.new(product_params)
    
    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end
  
  def edit
    authorize_admin!
    
    # Drivers cannot edit products
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot edit products.'
      return
    end
  end
  
  def update
    authorize_admin!
    
    # Drivers cannot update products
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot update products.'
      return
    end
    
    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    authorize_admin!
    
    # Drivers cannot delete products
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot delete products.'
      return
    end
    
    # Check if product has associated sales
    if @product.sales.exists?
      redirect_to products_path, alert: 'Cannot delete product with associated sales. Consider deactivating instead.'
    else
      @product.destroy
      redirect_to products_path, notice: 'Product was successfully deleted.'
    end
  end
  
  def toggle_status
    authorize_admin!
    
    # Drivers cannot toggle product status
    if current_user.driver?
      redirect_to products_path, alert: 'Drivers cannot change product status.'
      return
    end
    
    @product.toggle_status!
    redirect_to products_path, notice: "Product is now #{@product.active? ? 'active' : 'inactive'}."
  end
  
  private
  
  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to products_path, alert: 'Product not found.'
  end
  
  def product_params
    params.require(:product).permit(:name, :description, :price, :unit, :active)
  end
end