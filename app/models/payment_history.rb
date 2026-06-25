# app/models/payment_history.rb
class PaymentHistory < ApplicationRecord
  include Auditable
  
  belongs_to :sale
  belongs_to :user, optional: true

  has_one_attached :proof_attachment  # For storing uploaded files

  # PaperTrail for versioning
  #has_paper_trail

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
    ActivityLog.create!(
      user: user,
      action: 'payment_status_change',
      resource_type: 'Sale',
      resource_id: sale_id,
      details: "Payment status changed from #{old_status} to #{new_status}#{notes.present? ? ". Notes: #{notes}" : ''}",
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  rescue => e
    Rails.logger.error "Failed to create activity log: #{e.message}"
  end

  # Override Auditable methods
  def log_details
    "Payment history for Sale ##{sale_id}: #{old_status} → #{new_status}"
  end
end