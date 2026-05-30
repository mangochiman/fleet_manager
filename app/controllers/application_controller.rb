
class ApplicationController < ActionController::Base
  include WickedPdf::PdfHelper
  before_action :set_current_attributes
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :phone, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :phone])
  end
  
  private
  
  def set_current_attributes
    Current.ip_address = request.remote_ip
    Current.user_agent = request.user_agent
    Current.current_user = current_user
  end
  
  def after_sign_in_path_for(resource)
    dashboard_path
  end
  
  def after_sign_out_path_for(resource)
    new_user_session_path
  end
end