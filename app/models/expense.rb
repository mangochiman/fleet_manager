class Expense < ApplicationRecord
  belongs_to :vehicle
  belongs_to :recorded_by, class_name: 'User', optional: true

  validates :category, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :description, presence: true

  # Category constants instead of enum
  CATEGORIES = {
    'salaries' => 'salaries',
    'service' => 'service',
    'breakdown' => 'breakdown',
    'tires' => 'tires',
    'fuel' => 'fuel',
    'others' => 'others'
  }.freeze

  def category_name
    CATEGORIES[category] || category
  end

  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }

  before_validation :set_default_date

  private

  def set_default_date
    self.expense_date ||= Date.current
  end
end