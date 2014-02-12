class Source < ActiveRecord::Base
	belongs_to :portfolio
	has_many :transactions
	has_many :items, through: :transactions

	validates :name, presence: true, uniqueness: { scope: :portfolio_id }
end
