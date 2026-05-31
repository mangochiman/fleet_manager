class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_super_admin!, except: [:edit_password, :update_password]
  before_action :set_user, only: [:edit, :update, :destroy]
  
  def index
    @users = User.all.order(:role, :name)
    @roles = User::ROLES
  end
  
  def new
    @user = User.new
    @vehicles = Vehicle.active
  end
  
  def create
    @user = User.new(user_params)
    # Generate a random password if not provided
    if params[:user][:password].blank?
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end
    
    if @user.save
      message = "#{@user.name} was successfully created."
      message += " Password: #{generated_password}" if defined?(generated_password)
      redirect_to users_path, notice: message
    else
      @vehicles = Vehicle.active
      render :new
    end
  end
  
  def edit
    @vehicles = Vehicle.active
  end
  
  def update
    if @user.update(user_params)
      redirect_to users_path, notice: "#{@user.name} was successfully updated."
    else
      @vehicles = Vehicle.active
      render :edit
    end
  end
  
  def destroy
    # Prevent deleting yourself
    if @user == current_user
      redirect_to users_path, alert: 'You cannot delete your own account.'
      return
    end
    
    # Check if user has associated records
    if @user.sales.exists? || @user.expenses.exists?
      redirect_to users_path, alert: 'Cannot delete user with associated sales or expenses.'
      return
    end
    
    @user.destroy
    redirect_to users_path, notice: "#{@user.name} was successfully deleted."
  end
  
  # Password management for current user
  def edit_password
    @user = current_user
  end
  
  def update_password
  @user = current_user

  if params[:current_password].blank?
    flash.now[:alert] = "Current password cannot be blank."
    return render :edit_password
  end

  if params[:password].blank?
    flash.now[:alert] = "New password cannot be blank."
    return render :edit_password
  end

  if params[:password].length < 6
    flash.now[:alert] = "New password must be at least 6 characters."
    return render :edit_password
  end

  if params[:password] != params[:password_confirmation]
    flash.now[:alert] = "New password and confirmation do not match."
    return render :edit_password
  end

  # update_with_password expects a flat hash with these exact keys
  if @user.update_with_password(
    current_password: params[:current_password],
    password: params[:password],
    password_confirmation: params[:password_confirmation]
  )
    # Re-sign in the user so the session stays valid after password change
    sign_in(@user, bypass: true)
    redirect_to dashboard_path, notice: "Password was successfully updated."
  else
    if @user.errors[:current_password].any?
      flash.now[:alert] = "Current password is incorrect."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
    end
    render :edit_password
  end
end
  
  private
  
  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: 'User not found.'
  end
  
  def user_params
    params.require(:user).permit(:name, :email, :phone, :role, :vehicle_id, :password, :password_confirmation)
  end
end