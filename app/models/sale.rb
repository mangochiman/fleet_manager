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
  validates :transaction_date, presence: true
  validates :payment_status, inclusion: { in: %w[outstanding paid banked] }

  # Status constants
  STATUSES = {
    'outstanding' => 'outstanding',
    'paid' => 'paid',
    'banked' => 'banked'
  }.freeze

  scope :outstanding, -> { where(payment_status: 'outstanding') }
  scope :paid, -> { where(payment_status: 'paid') }
  scope :banked, -> { where(payment_status: 'banked') }
  scope :by_date_range, ->(start_date, end_date) { where(transaction_date: start_date..end_date) }

  def mark_as_paid!(proof_number: nil, proof_image: nil, updated_by: nil)
    return if payment_status == 'paid'
    
    old_status = payment_status
    update!(
      payment_status: 'paid',
      proof_of_payment_number: proof_number,
      proof_of_payment_image: proof_image
    )
    
    payment_histories.create!(
      user: updated_by,
      old_status: old_status,
      new_status: 'paid',
      proof_number: proof_number,
      proof_image: proof_image
    )
  end

  def mark_as_banked!(updated_by: nil)
    return if payment_status == 'banked'
    
    old_status = payment_status
    update!(payment_status: 'banked')
    
    payment_histories.create!(
      user: updated_by,
      old_status: old_status,
      new_status: 'banked'
    )
  end

  private

  def generate_transaction_id
    self.transaction_id = "TRX-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(4).upcase}"
  end

  def calculate_totals
    self.total_amount = quantity * unit_price if quantity && unit_price
  end

  def set_default_dates
    self.transaction_date ||= Date.current
  end
end