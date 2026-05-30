class CreatePaymentHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_histories do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :old_status
      t.string :new_status
      t.string :proof_number
      t.string :proof_image
      t.text :notes

      t.timestamps
    end
  end
end
