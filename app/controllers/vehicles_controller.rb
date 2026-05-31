class VehiclesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]
  
  # Role restrictions
  before_action :authorize_admin!, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    # Role-based filtering
    if current_user.driver?
      # Drivers can only see their assigned vehicle
      if current_user.vehicle_id.present?
        @vehicles = Vehicle.where(id: current_user.vehicle_id)
      else
        @vehicles = Vehicle.none
        redirect_to dashboard_path, alert: 'No vehicle assigned to your account.' and return
      end
    else
      # Admins, Managers, Super Admins see all vehicles
      @vehicles = Vehicle.all
    end
    
    @vehicles = @vehicles.order(:registration_number)
    
    # Apply filters
    if params[:status].present?
      @vehicles = @vehicles.where(status: params[:status])
    end
    
    if params[:search].present?
      @vehicles = @vehicles.where("registration_number LIKE ? OR make LIKE ? OR model LIKE ?", 
                                  "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    # Pagination
    @per_page = (params[:per_page] || 10).to_i
    @per_page = 50 if @per_page > 50
    @vehicles = @vehicles.paginate(page: params[:page], per_page: @per_page)
    
    # Stats (using direct SQL queries, not methods on collection)
    @total_vehicles = Vehicle.count
    @active_vehicles = Vehicle.active.count
    @maintenance_vehicles = Vehicle.in_maintenance.count
    
    # Calculate totals from sales and expenses tables
    @total_revenue = Sale.sum(:total_amount)
    @total_expenses = Expense.sum(:amount)
    @total_profit = @total_revenue - @total_expenses
  end
  
  def show
    # Drivers can only view their assigned vehicle
    if current_user.driver? && @vehicle.id != current_user.vehicle_id
      redirect_to vehicles_path, alert: 'You can only view your assigned vehicle.'
      return
    end
    
    @recent_sales = @vehicle.sales.includes(:product, :user).order(created_at: :desc).limit(5)
    @recent_expenses = @vehicle.expenses.order(expense_date: :desc).limit(5)
  end
  
  def new
    authorize_admin!
    
    # Drivers cannot create vehicles
    if current_user.driver?
      redirect_to vehicles_path, alert: 'Drivers cannot create vehicles.'
      return
    end
    
    @vehicle = Vehicle.new
  end
  
  def create
    authorize_admin!
    
    # Drivers cannot create vehicles
    if current_user.driver?
      redirect_to vehicles_path, alert: 'Drivers cannot create vehicles.'
      return
    end
    
    @vehicle = Vehicle.new(vehicle_params)
    
    if @vehicle.save
      redirect_to @vehicle, notice: 'Vehicle was successfully created.'
    else
      render :new
    end
  end
  
  def edit
    authorize_admin!
    
    # Drivers cannot edit vehicles
    if current_user.driver?
      redirect_to vehicles_path, alert: 'Drivers cannot edit vehicles.'
      return
    end
  end
  
  def update
    authorize_admin!
    
    # Drivers cannot update vehicles
    if current_user.driver?
      redirect_to vehicles_path, alert: 'Drivers cannot update vehicles.'
      return
    end
    
    if @vehicle.update(vehicle_params)
      redirect_to @vehicle, notice: 'Vehicle was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    authorize_admin!
    
    # Drivers cannot delete vehicles
    if current_user.driver?
      redirect_to vehicles_path, alert: 'Drivers cannot delete vehicles.'
      return
    end
    
    # Check if vehicle has associated records
    if @vehicle.sales.exists? || @vehicle.expenses.exists? || @vehicle.users.exists?
      redirect_to vehicles_path, alert: 'Cannot delete vehicle with associated sales, expenses, or drivers. Consider marking as retired instead.'
    else
      @vehicle.destroy
      redirect_to vehicles_path, notice: 'Vehicle was successfully deleted.'
    end
  end
  
  private
  
  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to vehicles_path, alert: 'Vehicle not found.'
  end
  
  def vehicle_params
    params.require(:vehicle).permit(:registration_number, :make, :model, :year, :status)
  end
end