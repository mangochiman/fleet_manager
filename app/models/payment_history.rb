class PaymentHistory < ApplicationRecord
  belongs_to :sale
  belongs_to :user

  validates :old_status, :new_status, presence: true

  after_create :log_activity

  private

  def log_activity
    ActivityLog.create(
      user: user,
      action: 'payment_status_change',
      resource_type: 'Sale',
      resource_id: sale_id,
      details: "Status changed from #{old_status} to #{new_status}"
    )
  end
end