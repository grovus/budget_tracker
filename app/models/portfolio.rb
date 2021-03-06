class Portfolio < ActiveRecord::Base
  belongs_to :user
  has_many :categories, -> { order :name }
  has_many :items, -> { uniq }, through: :categories, autosave: false
  has_many :transactions, -> { order :date_transacted }, through: :items, autosave: false
  has_many :sources, -> { order(:name).uniq }
  
  accepts_nested_attributes_for :sources, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :categories, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :transactions, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, length: { maximum: 50 }
  validates :categories, presence: true, length: { minimum: 1, too_short: "must contain at least %{count} category" }

  validate :validate_category_dupes

  def validate_category_dupes
  	unique_categories = categories.map(&:name).uniq
  	if unique_categories.size != categories.size
  	  errors.add(:categories, "must be unique") 
      
      dups = {}

      categories.each_with_index do |val, idx|
        (dups[val.name] ||= []) << idx
      end

      dups.delete_if {|k,v| v.size == 1}

      dups.each do |k, v| 
      	categories[v.last].errors.add(:name, "must be unique")
      end
    end
  end
end
