class Item < ActiveRecord::Base
  belongs_to :category
  has_many :transactions
  has_many :sources, through: :transactions

  validates :name,  presence: true, uniqueness: { scope: :category_id }, length: { maximum: 50 }

  def full_name
  	category.name + " / " + name
  end

end
