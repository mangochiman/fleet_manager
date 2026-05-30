class Vehicle < ApplicationRecord
  # Associations
  has_many :users, dependent: :nullify
  has_many :sales, dependent: :restrict_with_exception
  has_many :expenses, dependent: :restrict_with_exception
  
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
end