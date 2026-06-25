# app/models/activity_log.rb
class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :resource, polymorphic: true, optional: true

  validates :action, :resource_type, presence: true

  # Scopes for filtering
  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :by_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }
  
  # Fix: Use LIKE instead of ILIKE for MySQL compatibility
  scope :search_by_details, ->(query) { where("details LIKE ?", "%#{query}%") }
  
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: Time.current.beginning_of_month..Time.current.end_of_month) }

  # Action types for display
  ACTION_TYPES = {
    'create_sale' => 'Create Sale',
    'update_sale' => 'Update Sale',
    'delete_sale' => 'Delete Sale',
    'create_vehicle' => 'Create Vehicle',
    'update_vehicle' => 'Update Vehicle',
    'delete_vehicle' => 'Delete Vehicle',
    'create_product' => 'Create Product',
    'update_product' => 'Update Product',
    'delete_product' => 'Delete Product',
    'toggle_product' => 'Toggle Product Status',
    'create_expense' => 'Create Expense',
    'update_expense' => 'Update Expense',
    'delete_expense' => 'Delete Expense',
    'expense_paid' => 'Expense Marked Paid',
    'expense_unpaid' => 'Expense Marked Unpaid',
    'expense_cancelled' => 'Expense Cancelled',
    'record_payment' => 'Payment Recorded',
    'payment_status_change' => 'Payment Status Changed',
    'create_user' => 'Create User',
    'update_user' => 'Update User',
    'delete_user' => 'Delete User',
    'change_password' => 'Password Changed',
    'login' => 'Login',
    'logout' => 'Logout'
  }.freeze

  def display_time
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
  
  def display_date
    created_at.strftime("%B %d, %Y at %I:%M %p")
  end
  
  def action_name
    ACTION_TYPES[action] || action.titleize
  end
  
  def action_color
    if action.include?('create')
      'success'
    elsif action.include?('update')
      'info'
    elsif action.include?('delete') || action.include?('cancelled')
      'danger'
    elsif action.include?('paid') || action.include?('payment')
      'success'
    elsif action.include?('toggle')
      'warning'
    elsif action.include?('login') || action.include?('logout')
      'secondary'
    else
      'secondary'
    end
  end
  
  def user_name
    user&.name || 'System'
  end
  
  def resource_link
    return nil unless resource_type && resource_id
    
    begin
      resource = resource_type.constantize.find_by(id: resource_id)
      if resource
        case resource_type
        when 'Sale'
          Rails.application.routes.url_helpers.sale_path(resource)
        when 'Vehicle'
          Rails.application.routes.url_helpers.vehicle_path(resource)
        when 'Product'
          Rails.application.routes.url_helpers.product_path(resource)
        when 'Expense'
          Rails.application.routes.url_helpers.expense_path(resource)
        when 'User'
          Rails.application.routes.url_helpers.user_path(resource)
        else
          nil
        end
      end
    rescue => e
      nil
    end
  end
  
  def resource_display_name
    case resource_type
    when 'Sale'
      "Sale ##{resource_id}"
    when 'Vehicle'
      Vehicle.find_by(id: resource_id)&.registration_number || "Vehicle ##{resource_id}"
    when 'Product'
      Product.find_by(id: resource_id)&.name || "Product ##{resource_id}"
    when 'Expense'
      "Expense ##{resource_id}"
    when 'User'
      User.find_by(id: resource_id)&.name || "User ##{resource_id}"
    else
      "#{resource_type} ##{resource_id}"
    end
  end
  
  def parsed_details
    JSON.parse(details) rescue details
  end
  
  # For CSV export
  def to_csv_row
    [
      display_time,
      user_name,
      action_name,
      resource_type,
      resource_id,
      details,
      ip_address,
      user_agent
    ]
  end
end