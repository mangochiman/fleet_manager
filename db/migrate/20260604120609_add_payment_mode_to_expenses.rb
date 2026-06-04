class AddPaymentModeToExpenses < ActiveRecord::Migration[8.1]
  def change
    add_column :expenses, :payment_mode, :string
  end
end
