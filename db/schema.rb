# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_25_140314) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "action"
    t.datetime "created_at", null: false
    t.text "details"
    t.string "ip_address"
    t.integer "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.text "user_agent"
    t.bigint "user_id", null: false
    t.index ["action"], name: "index_activity_logs_on_action"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["ip_address"], name: "index_activity_logs_on_ip_address"
    t.index ["resource_type", "resource_id"], name: "index_activity_logs_on_resource_type_and_resource_id"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "expenses", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "expense_date", null: false
    t.datetime "paid_at"
    t.string "payment_mode"
    t.string "payment_reference"
    t.string "payment_status", default: "pending", null: false
    t.bigint "recorded_by_id"
    t.string "supporting_document"
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id", null: false
    t.index ["category"], name: "index_expenses_on_category"
    t.index ["expense_date"], name: "index_expenses_on_expense_date"
    t.index ["paid_at"], name: "index_expenses_on_paid_at"
    t.index ["payment_status"], name: "index_expenses_on_payment_status"
    t.index ["recorded_by_id"], name: "index_expenses_on_recorded_by_id"
    t.index ["vehicle_id"], name: "index_expenses_on_vehicle_id"
  end

  create_table "payment_histories", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "new_status"
    t.text "notes"
    t.string "old_status"
    t.string "proof_image"
    t.string "proof_number"
    t.bigint "sale_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["sale_id"], name: "index_payment_histories_on_sale_id"
    t.index ["user_id"], name: "index_payment_histories_on_user_id"
  end

  create_table "products", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "unit"
    t.datetime "updated_at", null: false
  end

  create_table "sales", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.text "notes"
    t.decimal "paid_amount", precision: 10
    t.date "payment_due_date"
    t.string "payment_method"
    t.string "payment_status", default: "outstanding"
    t.decimal "price_at_sale", precision: 10, scale: 2, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.string "proof_of_payment_image"
    t.string "proof_of_payment_number"
    t.integer "quantity", null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.date "transaction_date", null: false
    t.string "transaction_id", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "vehicle_id", null: false
    t.index ["customer_name"], name: "index_sales_on_customer_name"
    t.index ["payment_status"], name: "index_sales_on_payment_status"
    t.index ["price_at_sale"], name: "index_sales_on_price_at_sale"
    t.index ["product_id"], name: "index_sales_on_product_id"
    t.index ["transaction_id"], name: "index_sales_on_transaction_id", unique: true
    t.index ["user_id"], name: "index_sales_on_user_id"
    t.index ["vehicle_id"], name: "index_sales_on_vehicle_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0
    t.datetime "updated_at", null: false
    t.bigint "vehicle_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["vehicle_id"], name: "index_users_on_vehicle_id"
  end

  create_table "vehicles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "make"
    t.string "model"
    t.string "registration_number", null: false
    t.string "status", default: "active"
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["registration_number"], name: "index_vehicles_on_registration_number", unique: true
  end

  create_table "versions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", limit: 191, null: false
    t.text "object", size: :long
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "expenses", "users", column: "recorded_by_id"
  add_foreign_key "expenses", "vehicles"
  add_foreign_key "payment_histories", "sales"
  add_foreign_key "payment_histories", "users"
  add_foreign_key "sales", "products"
  add_foreign_key "sales", "users"
  add_foreign_key "sales", "vehicles"
  add_foreign_key "users", "vehicles"
end
