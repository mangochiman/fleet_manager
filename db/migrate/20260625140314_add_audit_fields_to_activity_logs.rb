# db/migrate/20260625000000_add_audit_fields_to_activity_logs.rb
class AddAuditFieldsToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    # Add columns if they don't exist
    add_column :activity_logs, :ip_address, :string unless column_exists?(:activity_logs, :ip_address)
    add_column :activity_logs, :user_agent, :text unless column_exists?(:activity_logs, :user_agent)
    
    # Add indexes for better performance
    add_index :activity_logs, :user_id if !index_exists?(:activity_logs, :user_id)
    add_index :activity_logs, [:resource_type, :resource_id] if !index_exists?(:activity_logs, [:resource_type, :resource_id])
    add_index :activity_logs, :action if !index_exists?(:activity_logs, :action)
    add_index :activity_logs, :created_at if !index_exists?(:activity_logs, :created_at)
    add_index :activity_logs, :ip_address if !index_exists?(:activity_logs, :ip_address)
  end
end