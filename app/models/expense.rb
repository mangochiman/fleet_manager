class Expense < ApplicationRecord
  belongs_to :vehicle
  belongs_to :recorded_by, class_name: 'User', optional: true
  has_one_attached :receipt

  validates :category, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :description, presence: true

  # Category constants
  CATEGORIES = {
    'fuel' => 'Fuel',
    'service' => 'Service & Maintenance',
    'breakdown' => 'Breakdown Repairs',
    'tires' => 'Tires',
    'salaries' => 'Salaries',
    'insurance' => 'Insurance',
    'permits' => 'Permits & Licenses',
    'others' => 'Others'
  }.freeze

  def category_name
    CATEGORIES[category] || category.titleize
  end

  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :by_category, ->(category) { where(category: category) }
  scope :this_month, -> { where(expense_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :this_year, -> { where(expense_date: Date.current.beginning_of_year..Date.current.end_of_year) }

  before_validation :set_default_date

  def receipt_attached?
    receipt.attached?
  end

  def display_amount
    ActionController::Base.helpers.number_to_currency(amount)
  end

  private

  def set_default_date
    self.expense_date ||= Date.current
  end
end