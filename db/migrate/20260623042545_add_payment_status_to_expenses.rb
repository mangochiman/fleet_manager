# db/migrate/20260623000000_add_payment_status_to_expenses.rb
class AddPaymentStatusToExpenses < ActiveRecord::Migration[8.1]
  def change
    # Add payment_status with default 'pending' for existing records
    add_column :expenses, :payment_status, :string, default: 'pending', null: false
    
    # Add paid_at timestamp to track when payment was completed
    add_column :expenses, :paid_at, :datetime
    
    # Add payment_reference for tracking payment confirmations
    add_column :expenses, :payment_reference, :string
    
    # Add indexes for performance
    add_index :expenses, :payment_status
    add_index :expenses, :paid_at
    
    # For existing records: set payment_status based on payment_mode
    # If payment_mode is 'cash', 'bank_transfer', 'cheque', 'credit_card', 
    # 'tnm_mpamba', 'airtel_money' - they are likely paid
    # If payment_mode is 'other' or nil - they are pending
    reversible do |dir|
      dir.up do
        # Set default payment_status for existing records
        # This is safe - it won't fail if columns don't exist yet
        execute <<-SQL
          UPDATE expenses 
          SET payment_status = 'paid' 
          WHERE payment_mode IN ('cash', 'bank_transfer', 'cheque', 'credit_card', 'tnm_mpamba', 'airtel_money')
            AND payment_status = 'pending'
        SQL
        
        # For records with 'other' payment mode, check if they're likely paid
        # We'll keep them as 'pending' by default - user can update manually
        # Also set paid_at for existing paid records to created_at
        execute <<-SQL
          UPDATE expenses 
          SET paid_at = created_at 
          WHERE payment_status = 'paid'
            AND paid_at IS NULL
        SQL
      end
    end
  end
end