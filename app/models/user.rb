class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  belongs_to :vehicle, optional: true
  has_many :sales, foreign_key: :user_id, dependent: :restrict_with_exception
  has_many :recorded_expenses, class_name: 'Expense', foreign_key: :recorded_by, dependent: :nullify
  has_many :payment_histories, dependent: :destroy
  has_many :activity_logs, dependent: :nullify

  # Validations
  validates :name, presence: true
  validates :phone, format: { with: /\A\+?[\d\s\-\(\)]+\z/, allow_blank: true }

  # Role constants
  ROLES = {
    0 => 'driver',
    1 => 'admin',
    2 => 'manager',
    3 => 'super_admin'
  }.freeze

  # Instance methods for role checking
  def role_name
    ROLES[role] || 'driver'
  end

  def driver?
    role == 0
  end

  def admin?
    role == 1
  end

  def manager?
    role == 2
  end

  def super_admin?
    role == 3
  end

  def admin_or_higher?
    admin? || manager? || super_admin?
  end

  def can_manage_payments?
    admin? || manager? || super_admin?
  end

  def can_view_reports?
    manager? || super_admin?
  end

  def display_name
    "#{name} (#{role_name.titleize})"
  end

  # Scopes
  scope :drivers, -> { where(role: 0) }
  scope :admins, -> { where(role: 1) }
  scope :managers, -> { where(role: 2) }
  scope :super_admins, -> { where(role: 3) }
end