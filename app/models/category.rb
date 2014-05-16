class Category < ActiveRecord::Base

  before_create :unique_per_portfolio?

  belongs_to :portfolio
  has_many :items

  accepts_nested_attributes_for :items, allow_destroy: true

  validates :name,  presence: true, uniqueness: { scope: :portfolio_id }, length: { maximum: 50 }
  validates :items, length: { minimum: 1, too_short: "must contain at least %{count} item" }

  validates :portfolio_id, uniqueness: { scope: :name }

  validate :validate_item_dupes

  def validate_item_dupes
  	unique_items = items.map(&:name).uniq
  	if unique_items.size != items.size
  	  errors.add(:items, "must be unique") 

  	  dups = {}

      items.each_with_index do |val, idx|
        (dups[val.name] ||= []) << idx
      end

      dups.delete_if {|k,v| v.size == 1}

      dups.each do |k, v|
        v.shift
        v.each do |idx| 
      	  items[idx].errors.add(:name, "must be unique")
      	end
      end
    end
  end

  def unique_per_portfolio?
  	portfolio = Portfolio.find(self.portfolio_id)
  	category = portfolio.categories.all(conditions: ["name = ?", self.name])

		self.errors.add(:name, "Category name should be unique") if category.size > 0
  end
end
