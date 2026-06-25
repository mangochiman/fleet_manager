# app/models/vehicle.rb
class Vehicle < ApplicationRecord
  include Auditable
  
  # Associations
  has_many :users, dependent: :nullify
  has_many :sales, dependent: :restrict_with_exception
  has_many :expenses, dependent: :restrict_with_exception
  
  # PaperTrail for versioning
  has_paper_trail
  
  # Validations
  validates :registration_number, presence: true, uniqueness: true
  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true, numericality: { greater_than: 1900, less_than_or_equal_to: Date.current.year + 1 }
  validates :status, inclusion: { in: %w[active maintenance retired] }
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :in_maintenance, -> { where(status: 'maintenance') }
  scope :retired, -> { where(status: 'retired') }
  
  # Callbacks for audit logging
  after_create :log_creation
  after_update :log_update
  after_destroy :log_destroy
  
  # Methods
  def total_sales
    sales.sum(:total_amount)
  end
  
  def total_expenses
    expenses.sum(:amount)
  end
  
  def profit
    total_sales - total_expenses
  end
  
  def profit_margin
    return 0 if total_sales == 0
    (profit / total_sales.to_f * 100).round(2)
  end
  
  def display_name
    "#{registration_number} - #{make} #{model} (#{year})"
  end
  
  def short_name
    registration_number
  end
  
  def status_badge_class
    case status
    when 'active'
      'badge-paid'
    when 'maintenance'
      'badge-outstanding'
    else
      'badge-inactive'
    end
  end

  private

  # Audit logging methods
  def log_creation
    log_activity('create_vehicle', "Vehicle #{registration_number} created. Make: #{make}, Model: #{model}, Year: #{year}, Status: #{status}")
  end

  def log_update
    if saved_changes.present?
      # Skip logging if only updated_at changed
      return if saved_changes.keys == ['updated_at']
      
      changes = saved_changes.map do |attr, (old_val, new_val)|
        # Skip timestamps for cleaner logs
        next if attr == 'updated_at'
        "#{attr}: #{old_val} → #{new_val}"
      end.compact.join(", ")
      
      log_activity('update_vehicle', "Vehicle #{registration_number} updated: #{changes}") if changes.present?
    end
  end

  def log_destroy
    log_activity('delete_vehicle', "Vehicle #{registration_number} deleted. Make: #{make}, Model: #{model}, Year: #{year}, Status: #{status}")
  end

  def log_details
    "Vehicle #{registration_number} - #{make} #{model} (#{year})"
  end
end