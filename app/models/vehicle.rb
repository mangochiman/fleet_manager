class Vehicle < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :sales, dependent: :restrict_with_exception
  has_many :expenses, dependent: :restrict_with_exception

  validates :registration_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active maintenance retired] }

  scope :active, -> { where(status: 'active') }
  scope :in_maintenance, -> { where(status: 'maintenance') }

  def total_sales
    sales.sum(:total_amount)
  end

  def total_expenses
    expenses.sum(:amount)
  end

  def profit
    total_sales - total_expenses
  end

  def display_name
    "#{registration_number} - #{make} #{model}"
  end
end