class Sale < ApplicationRecord
  belongs_to :user
  belongs_to :vehicle
  belongs_to :product
  has_many :payment_histories, dependent: :destroy

  before_validation :generate_transaction_id, on: :create
  before_validation :calculate_totals, on: :create
  before_create :set_default_dates

  validates :customer_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_status, inclusion: { in: %w[outstanding partial paid banked] }
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Status helper methods
  def outstanding?
    payment_status == 'outstanding'
  end

  def partial?
    payment_status == 'partial'
  end

  def paid?
    payment_status == 'paid'
  end

  def banked?
    payment_status == 'banked'
  end

  def remaining_balance
    total_amount - (paid_amount || 0)
  end

  def payment_percentage
    return 0 if total_amount == 0
    ((paid_amount || 0) / total_amount.to_f * 100).round
  end

  # Scopes
  scope :outstanding, -> { where(payment_status: 'outstanding') }
  scope :partial, -> { where(payment_status: 'partial') }
  scope :paid, -> { where(payment_status: 'paid') }
  scope :banked, -> { where(payment_status: 'banked') }
  scope :by_date_range, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }

  def record_payment!(amount:, reference_number: nil, proof_image: nil, notes: nil, updated_by: nil)
    return if amount <= 0
    
    old_status = payment_status
    new_paid_amount = (paid_amount || 0) + amount
    
    # Determine new status
    new_status = if new_paid_amount >= total_amount
      'paid'
    elsif new_paid_amount > 0
      'partial'
    else
      'outstanding'
    end
    
    update!(
      paid_amount: new_paid_amount,
      payment_status: new_status,
      proof_of_payment_number: reference_number,
      proof_of_payment_image: proof_image
    )
    
    payment_histories.create!(
      user: updated_by,
      old_status: old_status,
      new_status: new_status,
      proof_number: reference_number,
      proof_image: proof_image,
      notes: "#{notes}\nPayment amount: #{ActionController::Base.helpers.number_to_currency(amount)}".strip
    )
  end

  def mark_as_paid!(proof_number: nil, proof_image: nil, notes: nil, updated_by: nil)
    return if paid?
    
    old_status = payment_status
    
    update!(
      payment_status: 'paid',
      paid_amount: total_amount,
      proof_of_payment_number: proof_number,
      proof_of_payment_image: proof_image
    )
    
    payment_histories.create!(
      user: updated_by,
      old_status: old_status,
      new_status: 'paid',
      proof_number: proof_number,
      proof_image: proof_image,
      notes: notes
    )
  end

  def mark_as_banked!(notes: nil, updated_by: nil)
    return if banked?
    
    old_status = payment_status
    update!(payment_status: 'banked')
    
    payment_histories.create!(
      user: updated_by,
      old_status: old_status,
      new_status: 'banked',
      notes: notes
    )
  end

  private

  def generate_transaction_id
    self.transaction_id = "TRX-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def calculate_totals
    self.total_amount = quantity * unit_price if quantity && unit_price
    self.paid_amount ||= 0
  end

  def set_default_dates
    self.transaction_date ||= Date.current
  end
end