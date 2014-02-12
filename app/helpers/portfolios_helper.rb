module PortfoliosHelper
	#GLOBAL_CATEGORIES = %w[Housing Transportation Health Education Charity Savings Investment Entertainment Pets Vacation Subscriptions Miscellaneous]
	GLOBAL_CATEGORIES = %w[Housing Transportation Health Education]

	def all_categories
		all = GLOBAL_CATEGORIES
		all << 'An extra category'
	end
end
