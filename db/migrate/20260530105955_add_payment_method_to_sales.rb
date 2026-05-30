class AddPaymentMethodToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :payment_method, :string
  end
end
