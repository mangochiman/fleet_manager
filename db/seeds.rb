# Clear existing data (optional - be careful in production!)
puts "Cleaning existing data..."
Expense.destroy_all if defined?(Expense)
Sale.destroy_all if defined?(Sale)
PaymentHistory.destroy_all if defined?(PaymentHistory)
ActivityLog.destroy_all if defined?(ActivityLog)
User.destroy_all
Vehicle.destroy_all
Product.destroy_all

# Create vehicles
puts "Creating vehicles..."
vehicle1 = Vehicle.create!(
  registration_number: 'KCA 123A',
  make: 'Mercedes-Benz',
  model: 'Actros',
  year: 2022,
  status: 'active'
)

vehicle2 = Vehicle.create!(
  registration_number: 'KCB 456B',
  make: 'Volvo',
  model: 'FH16',
  year: 2023,
  status: 'active'
)

puts "✓ Created #{Vehicle.count} vehicles"

# Create products
puts "Creating products..."
products = [
  { name: 'Premium Diesel', description: 'High quality diesel fuel', price: 120.50, unit: 'liters', active: true },
  { name: 'Regular Petrol', description: 'Standard unleaded petrol', price: 115.00, unit: 'liters', active: true },
  { name: 'Lubricant Oil', description: 'Engine lubricating oil', price: 850.00, unit: 'liters', active: true },
  { name: 'Truck Tires', description: 'Heavy duty truck tires', price: 25000.00, unit: 'piece', active: true }
]

products.each do |product|
  Product.create!(product)
end

puts "✓ Created #{Product.count} products"

# Create admin user (role = 3 for super_admin)
puts "Creating admin user..."
admin = User.create!(
  email: 'admin@fleet.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'System Admin',
  phone: '+1234567890',
  role: 3  # super_admin
)

puts "✓ Created admin user"

# Create a driver user (role = 0 for driver)
puts "Creating driver user..."
driver = User.create!(
  email: 'driver@fleet.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'John Driver',
  phone: '+9876543210',
  role: 0,  # driver
  vehicle: vehicle1
)

puts "✓ Created driver user"

# Create a manager user (role = 2 for manager)
puts "Creating manager user..."
manager = User.create!(
  email: 'manager@fleet.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'Sarah Manager',
  phone: '+5555555555',
  role: 2,  # manager
  vehicle: nil
)

puts "✓ Created manager user"

# Create sample sales
puts "Creating sample sales..."
product = Product.first

20.times do |i|
  status = ['outstanding', 'paid', 'banked'].sample
  days_ago = rand(1..60)
  
  Sale.create!(
    user: [admin, driver, manager].sample,
    vehicle: [vehicle1, vehicle2].sample,
    product: product,
    customer_name: "Customer #{i+1}",
    customer_phone: "+2547#{rand(1000000..9999999)}",
    quantity: rand(10..100),
    unit_price: product.price,
    total_amount: rand(1000..50000),
    transaction_date: days_ago.days.ago,
    payment_status: status
  )
end

puts "✓ Created #{Sale.count} sample sales"

# Create sample expenses
puts "Creating sample expenses..."
expense_categories = ['fuel', 'service', 'breakdown', 'tires', 'salaries', 'others']
descriptions = [
  'Fuel for Nairobi trip',
  'Regular maintenance service',
  'Emergency roadside repair',
  'New set of tires',
  'Driver monthly salary',
  'Miscellaneous expenses'
]

15.times do |i|
  Expense.create!(
    vehicle: [vehicle1, vehicle2].sample,
    category: expense_categories.sample,
    amount: rand(1000..50000),
    expense_date: rand(1..60).days.ago,
    description: descriptions.sample,
    recorded_by: admin
  )
end

puts "✓ Created #{Expense.count} sample expenses"

puts "\n" + "="*50
puts "✅ SEED COMPLETED SUCCESSFULLY!"
puts "="*50
puts "\n📋 LOGIN CREDENTIALS:"
puts "   Admin Email: admin@fleet.com"
puts "   Admin Password: password123"
puts ""
puts "   Driver Email: driver@fleet.com"
puts "   Driver Password: password123"
puts ""
puts "   Manager Email: manager@fleet.com"
puts "   Manager Password: password123"
puts "\n🚀 You can now run: rails server"
puts "   Then visit: http://localhost:3000"
puts "="*50