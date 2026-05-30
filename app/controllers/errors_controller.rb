class ErrorsController < ApplicationController
  # Skip authentication for error pages - must be at the top
  skip_before_action :authenticate_user!, raise: false
  
  # Also skip other before_actions if any
  skip_before_action :set_current_attributes, raise: false if respond_to?(:set_current_attributes)
  
  layout false
  
  def not_found
    render status: :not_found, formats: [:html]
  end
  
  def internal_server_error
    render status: :internal_server_error, formats: [:html]
  end
  
  def unprocessable_entity
    render status: :unprocessable_entity, formats: [:html]
  end
end