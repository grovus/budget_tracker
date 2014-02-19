class PortfoliosController < ApplicationController
  before_action :store_location, only: [:show, :manage]
  before_action :check_setup, only: [:show, :manage]

  helper_method :sort_column, :sort_direction

  def new
  	@portfolio = Portfolio.new
  	view_context.all_categories.each do |cat| 
  	  category = @portfolio.categories.build(name: cat)
  	  # add an empty subcategory item
  	  category.items.build
  	end
  end

  def create
  	@portfolio = current_user.build_portfolio(portfolio_params)
  	if @portfolio.save
  		flash[:success] = 'Well hello!'

  		# need to set up portfolio categories / items
  		# should prepopulate with some defaults
    	
    	view_context.all_categories(true).each do |cat| 
    	  category = @portfolio.categories.build(name: cat)
    	  # add an empty subcategory
  	      category.items.build(name: 'My item')
  	    end

  	    @portfolio.save!

        Rails.logger.debug "******** There are #{@portfolio.categories.size} categories"  	    

  		redirect_to setup_url
  	else
  		render 'new'
  	end
  end

  def destroy
  	@portfolio = Portfolio.find(params[:id])
  	if current_user?(@portfolio.user)
  		@portfolio.destroy
  		flash[:success] = "Portfolio deleted"
  	else
  		flash[:error] = "Cannot destroy unowned portfolio"
  	end
  	redirect_to current_user
  end

  def show
  	@portfolio = Portfolio.find(params[:id])
  	session[:referrer_page] = request.env['HTTP_REFERER']

    #TODO: also reject based on range of interest; for instance, 
    # may only want all months up to current month or only current month
    @months = Date::ABBR_MONTHNAMES.reject { |x| x.nil? }

    # populate transactions hash
    @transactions = {}

    #TODO: sort hash keys by some ordinal as selected by user (ie. rank categories/items)
    grouped_categories = @portfolio.transactions.group_by { |t| t.item.category }
    
    grouped_categories.keys.sort.each do |category|
    	grouped_items = grouped_categories[category].group_by { |t| t.item }
  		
  		@transactions[category] = {}

    	grouped_items.keys.sort.each do |item|
    	    @transactions[category][item] = 
    	      grouped_items[item].group_by { |t| t.date_transacted.beginning_of_month.strftime('%b') }
    	end
    end

    # now group by date column to calculate aggregates
    @totals = {}
    @totals['Monthly Total'] = {}
    grouped_by_month = @portfolio.transactions.group_by { |t| t.date_transacted.beginning_of_month }
    grouped_by_month.keys.sort.each do |month|
    	grouped_by_category = grouped_by_month[month].group_by { |t| t.item.category }
    	
    	grouped_by_category.keys.sort.each do |category|
    		@totals[category] ||= {}
    		@totals[category][month.strftime('%b')] = grouped_by_category[category].collect(&:amount).sum
    	end
    	
    	@totals['Monthly Total'][month.strftime('%b')] = grouped_by_category.values.flatten.collect(&:amount).sum
    end
  end

  def transactions_monthly
  	@portfolio = Portfolio.find(params[:id])
    
    start_date = DateTime.civil( *params.values_at( :year, :month ).map(&:to_i) )
    @month = Date::ABBR_MONTHNAMES[params[:month].to_i]
    @year = params[:year]

  	@transactions = @portfolio.transactions.where({ date_transacted: start_date..(start_date + 1.month)})
  										    .paginate(page: params[:page], per_page: 20)
  											.order(sort_column + " " + sort_direction)
  end

  def manage
  	@portfolio = current_user.portfolio
  	@category = Category.new
  	@source = Source.new
  end

  def update
  	if current_user.portfolio.update_attributes(params)
  	  flash[:success] = "Successfuly updated portfolio"
  	else
  	  render 'new'
  	end

  	render 'edit'
  end

  def setup
  	@global_categories = PortfoliosHelper::GLOBAL_CATEGORIES
    
    Rails.logger.debug "******** There are #{current_user.portfolio.categories.size} categories"  	    
  end

  def create_categories
  	@portfolio = current_user.portfolio
  	@portfolio.update_attributes(portfolio_params)
  	if @portfolio.save!
  		flash[:success] = 'Portfolio successfully updated'
  	else
  		flash[:error] = 'Failed to update portfolio'
  	end

  	redirect_to setup_items_url
  end

  def setup_items
  	@categories = current_user.portfolio.categories.paginate(page: params[:page], per_page: 1)
  end

  private

  	def check_setup
  		redirect_to 'setup' unless current_user.portfolio.setup_complete?
  		# also need to check categories?
  	end

    def portfolio_params
      params.require(:portfolio).permit(:name, categories_attributes: [:id, :name, :_destroy, items_attributes: [:id, :name, :_destroy] ])
    end

    def sort_column
      Transaction.column_names.include?(params[:sort]) ? params[:sort] : "date_transacted"
    end
  
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

end
