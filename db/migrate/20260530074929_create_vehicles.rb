class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.string :registration_number, null: false
      t.string :make
      t.string :model
      t.integer :year
      t.string :status, default: 'active'
      t.timestamps
    end
    add_index :vehicles, :registration_number, unique: true
  end
end