class CreateSales < ActiveRecord::Migration[8.1]
  def change
    create_table :sales do |t|
      t.string :transaction_id, null: false
      t.references :user, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :customer_name, null: false
      t.string :customer_phone
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.date :transaction_date, null: false
      t.string :payment_status, default: 'outstanding'
      t.string :proof_of_payment_number
      t.string :proof_of_payment_image
      t.text :notes
      t.timestamps
    end
    add_index :sales, :transaction_id, unique: true
    add_index :sales, :customer_name
    add_index :sales, :payment_status
  end
end