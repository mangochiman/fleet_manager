# app/models/expense.rb
class Expense < ApplicationRecord
  include Auditable
  
  belongs_to :vehicle
  belongs_to :recorded_by, class_name: 'User', optional: true
  has_one_attached :receipt

  # PaperTrail for versioning
  #has_paper_trail

  validates :category, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expense_date, presence: true
  validates :description, presence: true
  validates :payment_mode, presence: true
  validates :payment_status, presence: true, inclusion: { in: %w[pending paid cancelled] }

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

  # Payment modes
  PAYMENT_MODES = {
    'cash' => 'Cash',
    'bank_transfer' => 'Bank Transfer',
    'cheque' => 'Cheque',
    'credit_card' => 'Credit Card',
    'tnm_mpamba' => 'TNM Mpamba',
    'airtel_money' => 'Airtel Money',
    'other' => 'Other'
  }.freeze

  # Payment statuses
  PAYMENT_STATUSES = {
    'pending' => 'Pending',
    'paid' => 'Paid',
    'cancelled' => 'Cancelled'
  }.freeze

  # Scopes
  scope :pending, -> { where(payment_status: 'pending') }
  scope :paid, -> { where(payment_status: 'paid') }
  scope :cancelled, -> { where(payment_status: 'cancelled') }
  scope :unpaid, -> { where(payment_status: ['pending', 'cancelled']) }
  scope :by_payment_status, ->(status) { where(payment_status: status) if status.present? }
  scope :by_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) }
  scope :by_date_range, ->(start_date, end_date) { where(expense_date: start_date..end_date) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_payment_mode, ->(payment_mode) { where(payment_mode: payment_mode) }
  scope :this_month, -> { where(expense_date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :this_year, -> { where(expense_date: Date.current.beginning_of_year..Date.current.end_of_year) }

  before_validation :set_default_date
  before_validation :set_default_payment_status, on: :create

  # Callbacks for audit logging
  after_create :log_creation
  after_update :log_update
  after_destroy :log_destroy

  def category_name
    CATEGORIES[category] || category.titleize
  end

  def payment_mode_name
    PAYMENT_MODES[payment_mode] || payment_mode.titleize rescue ''
  end

  def payment_status_name
    PAYMENT_STATUSES[payment_status] || payment_status.titleize
  end

  def pending?
    payment_status == 'pending'
  end

  def paid?
    payment_status == 'paid'
  end

  def cancelled?
    payment_status == 'cancelled'
  end

  def editable?
    pending?
  end

  def status_badge_class
    case payment_status
    when 'paid'
      'badge-paid'
    when 'cancelled'
      'badge-inactive'
    else
      'badge-outstanding'
    end
  end

  def receipt_attached?
    receipt.attached?
  end

  def display_amount
      ActionController::Base.helpers.number_to_currency(amount, unit: "MK ", format: "%u%n")
  end

  def mark_as_paid!(reference: nil, updated_by: nil)
    return if paid?
    
    transaction do
      update!(
        payment_status: 'paid',
        paid_at: Time.current,
        payment_reference: reference || payment_reference
      )
      
      ActivityLog.create!(
        user: updated_by,
        action: 'expense_paid',
        resource_type: 'Expense',
        resource_id: id,
        details: "Expense marked as paid. Reference: #{reference || 'N/A'}"
      )
    end
    true
  rescue => e
    Rails.logger.error "Failed to mark expense as paid: #{e.message}"
    false
  end

  def mark_as_pending!(updated_by: nil)
    return if pending?
    
    transaction do
      update!(
        payment_status: 'pending',
        paid_at: nil,
        payment_reference: nil
      )
      
      ActivityLog.create!(
        user: updated_by,
        action: 'expense_unpaid',
        resource_type: 'Expense',
        resource_id: id,
        details: "Expense marked as pending (unpaid)"
      )
    end
    true
  rescue => e
    Rails.logger.error "Failed to mark expense as pending: #{e.message}"
    false
  end

  def cancel!(updated_by: nil)
    return if cancelled?
    
    transaction do
      update!(
        payment_status: 'cancelled',
        paid_at: nil
      )
      
      ActivityLog.create!(
        user: updated_by,
        action: 'expense_cancelled',
        resource_type: 'Expense',
        resource_id: id,
        details: "Expense was cancelled"
      )
    end
    true
  rescue => e
    Rails.logger.error "Failed to cancel expense: #{e.message}"
    false
  end

  private

  def set_default_date
    self.expense_date ||= Date.current
  end

  def set_default_payment_status
    self.payment_status ||= 'pending'
  end

  # Audit logging methods
  def log_creation
    log_activity('create_expense', "Expense created. Vehicle: #{vehicle.registration_number}, Category: #{category_name}, Amount: #{display_amount}")
  end

  def log_update
    if saved_changes.present?
      # Skip logging if only updated_at changed
      return if saved_changes.keys == ['updated_at']
      
      changes = saved_changes.map do |attr, (old_val, new_val)|
        # Skip timestamps for cleaner logs
        next if attr == 'updated_at'
        # Format amount nicely
        if attr == 'amount'
          old_val = ActionController::Base.helpers.number_to_currency(old_val)
          new_val = ActionController::Base.helpers.number_to_currency(new_val)
        end
        "#{attr}: #{old_val} → #{new_val}"
      end.compact.join(", ")
      
      log_activity('update_expense', "Expense updated: #{changes}") if changes.present?
    end
  end

  def log_destroy
    log_activity('delete_expense', "Expense deleted. Vehicle: #{vehicle.registration_number}, Category: #{category_name}, Amount: #{display_amount}")
  end

  def log_details
    "Expense - Vehicle: #{vehicle.registration_number}, Category: #{category_name}, Amount: #{display_amount}"
  end
end