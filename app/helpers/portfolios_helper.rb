module PortfoliosHelper
	GLOBAL_CATEGORIES = %w[Housing Transportation Health Education Charity Savings Investment Entertainment Pets Vacation Subscriptions Miscellaneous]
	#GLOBAL_CATEGORIES = %w[Housing Transportation Health Education]

	def all_categories(shortlist = false)
		all = shortlist ? GLOBAL_CATEGORIES[0..3] : GLOBAL_CATEGORIES
		#all << 'An extra category'
	end
end
