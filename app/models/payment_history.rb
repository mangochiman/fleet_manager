class PaymentHistory < ApplicationRecord
  belongs_to :sale
  belongs_to :user, optional: true

  has_one_attached :proof_attachment  # For storing uploaded files

  validates :old_status, :new_status, presence: true

  scope :recent, -> { order(created_at: :desc).limit(10) }

  after_create :log_activity

  def status_change
    "#{old_status.titleize} → #{new_status.titleize}"
  end

  def display_time
    created_at.strftime("%d %b %Y at %I:%M %p")
  end

  def has_proof?
    proof_number.present? || proof_attachment.attached?
  end

  private

  def log_activity
    ActivityLog.create(
      user: user,
      action: 'payment_status_change',
      resource_type: 'Sale',
      resource_id: sale_id,
      details: "Status changed from #{old_status} to #{new_status}#{notes.present? ? ". Notes: #{notes}" : ''}"
    )
  rescue => e
    Rails.logger.error "Failed to create activity log: #{e.message}"
  end
end