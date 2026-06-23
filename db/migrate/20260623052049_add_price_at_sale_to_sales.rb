# db/migrate/20260623000002_add_price_at_sale_to_sales.rb
class AddPriceAtSaleToSales < ActiveRecord::Migration[8.1]
  def change
    # Add column to store the product price at the time of sale
    add_column :sales, :price_at_sale, :decimal, precision: 10, scale: 2, null: false, default: 0
    
    # Backfill existing sales with their current unit_price
    # This ensures historical data is preserved
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE sales 
          SET price_at_sale = unit_price 
          WHERE price_at_sale = 0
        SQL
      end
    end
    
    # Add index for reporting
    add_index :sales, :price_at_sale
  end
end