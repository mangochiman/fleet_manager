class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.string :category, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :expense_date, null: false
      t.text :description
      t.string :supporting_document
      t.references :recorded_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :expenses, :category
    add_index :expenses, :expense_date
  end
end