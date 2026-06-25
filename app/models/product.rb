# app/models/product.rb
class Product < ApplicationRecord
  include Auditable
  
  # Associations
  has_many :sales, dependent: :restrict_with_exception
  
  # PaperTrail for versioning
  has_paper_trail
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  # Callbacks
  before_validation :set_defaults
  after_create :log_creation
  after_update :log_update
  after_destroy :log_destroy
  
  # Methods
  def active?
    active
  end
  
  def toggle_status!
    update(active: !active)
    log_activity('toggle_product', "Product #{name} status changed to #{active? ? 'active' : 'inactive'}")
  end
  
  def total_sales_count
    sales.count
  end
  
  def total_revenue
    sales.sum(:total_amount)
  end
  
  def display_name
    "#{name} (#{unit})"
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
  end

  # Audit logging methods
  def log_creation
    log_activity('create_product', "Product #{name} created. Price: #{price}, Unit: #{unit}, Status: #{active? ? 'active' : 'inactive'}")
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
      
      log_activity('update_product', "Product #{name} updated: #{changes}") if changes.present?
    end
  end

  def log_destroy
    log_activity('delete_product', "Product #{name} deleted. Price: #{price}, Unit: #{unit}, Status: #{active? ? 'active' : 'inactive'}")
  end

  def log_details
    "Product #{name} - Price: #{price}, Unit: #{unit}"
  end
end