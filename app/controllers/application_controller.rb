class ApplicationController < ActionController::Base
  include WickedPdf::PdfHelper
  
  before_action :set_current_attributes
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_user_role, unless: :devise_controller?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end
  
  def check_user_role
    unless current_user
      redirect_to new_user_session_path
      return
    end
  end
  
  # Role authorization methods
  def authorize_admin!
    unless current_user&.admin? || current_user&.manager? || current_user&.super_admin?
      redirect_to dashboard_path, alert: 'You are not authorized to access this page.'
    end
  end
  
  def authorize_manager!
    unless current_user&.manager? || current_user&.super_admin?
      redirect_to dashboard_path, alert: 'You are not authorized to access this page.'
    end
  end
  
  def authorize_super_admin!
    unless current_user&.super_admin?
      redirect_to dashboard_path, alert: 'You are not authorized to access this page.'
    end
  end
  
  def authorize_driver!
    unless current_user&.driver?
      redirect_to dashboard_path, alert: 'Access denied. Driver privileges required.'
    end
  end
  
  private
  
  def set_current_attributes
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.current_user = current_user
  end
  
  def after_sign_in_path_for(resource)
    if resource.driver?
      sales_path  # Send drivers directly to their trips page
    else
      dashboard_path  # Admins/Managers go to dashboard
    end
  end
  
  def after_sign_out_path_for(resource)
    new_user_session_path
  end
end