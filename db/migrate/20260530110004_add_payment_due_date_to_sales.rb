class AddPaymentDueDateToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :payment_due_date, :date
  end
end
