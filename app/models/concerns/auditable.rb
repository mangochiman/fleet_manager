# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern
  
  included do
    # Enable PaperTrail for automatic versioning
    has_paper_trail
    
    # Callbacks for automatic audit logging
    after_create :log_creation
    after_update :log_update
    after_destroy :log_destroy
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
  
  # Log creation
  def log_creation
    log_activity("create_#{self.class.name.underscore}")
  end
  
  # Log update with changes
  def log_update
    if saved_changes.present?
      # Skip logging if only updated_at changed
      return if saved_changes.keys == ['updated_at']
      
      changes = saved_changes.map do |attr, (old_val, new_val)|
        # Skip timestamps for cleaner logs
        next if attr == 'updated_at'
        "#{attr}: #{old_val} → #{new_val}"
      end.compact.join(", ")
      
      log_activity("update_#{self.class.name.underscore}", changes) if changes.present?
    end
  end
  
  # Track deletion separately to preserve data
  def log_destroy
    log_activity("delete_#{self.class.name.underscore}")
  end
  
  # Track changes with before/after values (alternative method)
  def log_update_with_changes
    if saved_changes.present?
      changes_summary = saved_changes.map do |attr, (old_val, new_val)|
        "#{attr}: #{old_val} → #{new_val}"
      end.join(", ")
      log_activity("update_#{self.class.name.underscore}", changes_summary)
    end
  end
end