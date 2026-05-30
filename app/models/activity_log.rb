class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, :resource_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :by_resource, ->(type, id) { where(resource_type: type, resource_id: id) }

  def display_time
    created_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end