# Clear existing data (optional - be careful in production!)
puts "Cleaning existing data..."
PaymentHistory.destroy_all if defined?(PaymentHistory)
ActivityLog.destroy_all if defined?(ActivityLog)
Expense.destroy_all if defined?(Expense)
Sale.destroy_all if defined?(Sale)
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

# Create products - Construction Materials for Tipper Trucks
puts "Creating products..."
products = [
  { name: 'Sand', description: 'Sand', price: 280000, unit: 'tons', active: true },
  { name: 'All quarries',  description: 'All quarries', price: 200000, unit: 'tons', active: true },
  { name: 'Bricks',  description: 'Bricks', price: 200000, unit: 'tons', active: true },
  { name: 'Blocks',  description: 'Blocks', price: 300000, unit: 'tons', active: true },
  { name: 'Soil',     description: 'Soil', price: 200000, unit: 'tons', active: true },
  { name: 'Sock ware', description: 'Sock ware', price: 250000, unit: 'tons', active: true }
]

products.each { |attrs| Product.create!(attrs) }

puts "✓ Created #{Product.count} products"

# Create admin user (role = 3 for super_admin)
puts "Creating admin user..."
admin = User.create!(
  email: 'admin@fleet.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'System Admin',
  phone: '+265888888888',
  role: 3
)

puts "✓ Created admin user"

# Create a driver user (role = 0 for driver)
puts "Creating driver user..."
driver = User.create!(
  email: 'driver@fleet.com',
  password: 'password123',
  password_confirmation: 'password123',
  name: 'John Driver',
  phone: '+265999999999',
  role: 0,
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
  phone: '+265777777777',
  role: 2,
  vehicle: nil
)

puts "✓ Created manager user"

puts "✓ Created #{Sale.count} sample sales"

# Create sample expenses
puts "Creating sample expenses..."
expense_categories = ['fuel', 'service', 'breakdown', 'tires', 'salaries', 'others']
descriptions = [
  'Fuel for Lilongwe trip',
  'Regular maintenance service',
  'Emergency roadside repair',
  'New set of tires',
  'Driver monthly salary',
  'Miscellaneous expenses'
]

puts "\n" + "=" * 50
puts "✅ SEED COMPLETED SUCCESSFULLY!"
puts "=" * 50
puts "\n📋 LOGIN CREDENTIALS:"
puts "   Admin Email:   admin@fleet.com"
puts "   Admin Password: password123"
puts "   (Super Admin - Full access including user management)"
puts ""
puts "   Driver Email:  driver@fleet.com"
puts "   Driver Password: password123"
puts "   (Driver - Can only view own sales, assigned vehicle)"
puts ""
puts "   Manager Email: manager@fleet.com"
puts "   Manager Password: password123"
puts "   (Manager - Full access including reports)"
puts "\n📊 PRODUCTS LOADED:"
Product.all.each { |p| puts "   - #{p.name}: MK #{p.price} per #{p.unit}" }
puts "\n🚀 You can now run: rails server"
puts "   Then visit: http://localhost:3000"
puts "=" * 50