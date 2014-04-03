class Item < ActiveRecord::Base
  before_create :unique_per_category?

  belongs_to :category
  has_many :transactions
  has_many :sources, through: :transactions

  validates :name,  presence: true, uniqueness: { scope: :category_id }, length: { maximum: 50 }

  def full_name
  	category.name + " / " + name
  end

  def unique_per_category?
 	category = Category.find(self.category_id)
  	item = category.items.find(:all, :conditions => ["name = ?", self.name])

	if item.size > 0 
		self.errors.add(:name, "Item name should be unique")
	end  	
  end

end
