# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern
  
  included do
    # Enable PaperTrail for automatic versioning
    has_paper_trail
  end
  
  # Class methods
  module ClassMethods
    def audit_action(action, resource, details = {})
      ActivityLog.create!(
        user: Current.current_user,
        action: action,
        resource_type: resource.class.name,
        resource_id: resource.id,
        details: details.to_json,
        ip_address: Current.ip_address,
        user_agent: Current.user_agent
      )
    rescue => e
      Rails.logger.error "Failed to create audit log: #{e.message}"
    end
  end
  
  # Instance methods
  def log_activity(action, details = nil)
    ActivityLog.create!(
      user: Current.current_user,
      action: action,
      resource_type: self.class.name,
      resource_id: id,
      details: details || log_details,
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  rescue => e
    Rails.logger.error "Failed to log activity: #{e.message}"
  end
  
  # Override this in each model for custom details
  def log_details
    "#{self.class.name} ##{id}"
  end
  
  # Track deletion separately to preserve data
  def log_destroy
    log_activity("delete_#{self.class.name.underscore}")
  end
  
  # Track changes with before/after values
  def log_update_with_changes
    if saved_changes.present?
      changes_summary = saved_changes.map do |attr, (old_val, new_val)|
        "#{attr}: #{old_val} → #{new_val}"
      end.join(", ")
      log_activity("update_#{self.class.name.underscore}", changes_summary)
    end
  end
end
