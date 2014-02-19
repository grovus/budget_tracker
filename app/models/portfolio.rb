class Portfolio < ActiveRecord::Base
  belongs_to :user
  has_many :categories
  has_many :items, through: :categories
  has_many :transactions, through: :items
  has_many :sources
  
  accepts_nested_attributes_for :categories, allow_destroy: true, reject_if: :all_blank

  validates :name,  presence: true, length: { maximum: 50 }
end
