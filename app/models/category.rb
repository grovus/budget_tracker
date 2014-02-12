class Category < ActiveRecord::Base
  belongs_to :portfolio
  has_many :items

  accepts_nested_attributes_for :items, allow_destroy: true

  validates :name,  presence: true, uniqueness: { scope: :portfolio_id }, length: { maximum: 50 }
end
