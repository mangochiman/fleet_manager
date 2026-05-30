class AddPaidAmountToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :paid_amount, :decimal
  end
end
