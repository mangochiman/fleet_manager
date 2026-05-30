class Product < ApplicationRecord
  has_many :sales, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  before_validation :set_defaults

  def active?
    active
  end

  def toggle_status!
    update(active: !active)
  end

  private

  def set_defaults
    self.active = true if active.nil?
  end
end