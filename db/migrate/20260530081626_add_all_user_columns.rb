class AddAllUserColumns < ActiveRecord::Migration[8.1]
  def change
    # Add columns to users table with correct types
    add_column :users, :name, :string, null: false, default: ''
    add_column :users, :phone, :string
    add_column :users, :vehicle_id, :bigint  # Changed from :integer to :bigint
    
    # Add indexes
    add_index :users, :vehicle_id
    
    # Add foreign key
    add_foreign_key :users, :vehicles, column: :vehicle_id
  end
end