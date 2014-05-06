class Source < ActiveRecord::Base
	belongs_to :portfolio
	has_many :transactions
	has_many :items, through: :transactions

	validates :name, presence: true, uniqueness: { scope: :portfolio_id }

	scope :name_starts_with, ->(str) { where('lower(name) LIKE ?', "#{str.downcase}%") }
	scope :name_contains, ->(str) { where('lower(name) LIKE ?', "%#{str.downcase}%") }
end
