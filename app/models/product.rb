class Product < ApplicationRecord
  # Associations
  has_many :sales, dependent: :restrict_with_exception
  
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
  
  # Methods
  def active?
    active
  end
  
  def toggle_status!
    update(active: !active)
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
end