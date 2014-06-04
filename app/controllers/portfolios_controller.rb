class PortfoliosController < ApplicationController
  before_action :store_location, only: [:show, :manage]
  before_action :current_year, only: [:show, :transactions_monthly]
  before_action :no_items, only: [:to_csv]
  #before_action :check_setup, only: [:show, :manage]

  helper_method :sort_column, :sort_direction

  def new
  	@portfolio = Portfolio.new
  	view_context.all_categories(true).each do |cat| 
  	  category = @portfolio.categories.build(name: cat)
  	  # add an empty subcategory item
  	  category.items.build
  	end
  end

  def create
  	begin
  	@portfolio = current_user.build_portfolio(portfolio_params)
  	if @portfolio.save
  		flash[:success] = 'Well hello!'

  		# need to set up portfolio categories / items
  		# should prepopulate with some defaults
    	
    	#view_context.all_categories(true).each do |cat| 
    	#  category = @portfolio.categories.build(name: cat)
    	  # add an empty subcategory
  	    #  category.items.build(name: 'My item')
  	    #end

  	    #@portfolio.save!

        Rails.logger.debug "******** There are #{@portfolio.categories.size} categories"  	    

  		redirect_to @portfolio
  	else
  		render 'new'
  	end
  	
  	rescue ActiveRecord::RecordNotUnique
  		@portfolio.errors.add(:base, 'Categories and Items must be unique')
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
  	#@transaction = Transaction.new
  	#@transaction.date_transacted = Time.now.strftime("%Y-%m-%d")

  	@portfolio = Portfolio.find(params[:id])
  	session[:referrer_page] = request.env['HTTP_REFERER']

    #TODO: also reject based on range of interest; for instance, 
    # may only want all months up to current month or only current month
    @months = Date::ABBR_MONTHNAMES.reject { |x| x.nil? }

    # populate transactions hash
    @transactions = {}

    Rails.logger.debug "-------------------> GROUPING CATEGORIES <--------------------"

    current_transactions = @portfolio.transactions.full_select.expenses.for_year(@year)

    #TODO: sort hash keys by some ordinal as selected by user (ie. rank categories/items)
#    grouped_categories = @portfolio.transactions.full_select.for_year(@year).group_by { |t| t.item.category }
    grouped_categories = current_transactions.group_by(&:category_name)
    
    grouped_categories.keys.sort.each do |category|
    	#grouped_items = grouped_categories[category].group_by { |t| t.item }
      grouped_items = grouped_categories[category].group_by(&:item_name)
  		
  		@transactions[category] = {}

    	grouped_items.keys.sort.each do |item|
    	    @transactions[category][item] = 
    	      grouped_items[item].group_by { |t| t.date_transacted.beginning_of_month.strftime('%b') }
    	end
    end

    Rails.logger.debug "-------------------> GROUPING BY DATES <--------------------"

    # now group by date column to calculate aggregates
    @totals = {}
    @totals['Monthly Total'] = {}
    grouped_by_month = current_transactions.group_by { |t| t.date_transacted.beginning_of_month }
    grouped_by_month.keys.sort.each do |month|
      #grouped_by_category = grouped_by_month[month].group_by { |t| t.item.category }
      grouped_by_category = grouped_by_month[month].group_by(&:category_name)
    	
    	grouped_by_category.keys.sort.each do |category|
    		@totals[category] ||= {}
    		@totals[category][month.strftime('%b')] = grouped_by_category[category].collect(&:amount).sum
    	end
    	
    	@totals['Monthly Total'][month.strftime('%b')] = grouped_by_category.values.flatten.collect(&:amount).sum
    end

        Rails.logger.debug "-------------------> FINISHED GROUPING <--------------------"

    respond_to do |format|
      format.html
      format.csv { send_data to_csv(@transactions) }
      format.xls
    end  
  end

  def to_csv(transactions = {})
    CSV.generate do |csv|
      @months = Date::ABBR_MONTHNAMES.reject { |x| x.nil? }
      csv << ['Category', 'Item'] + @months + ['Totals', 'Average']
      overall_totals = ['Overall', '']
      overall_monthly_totals = {}
   
      transactions.keys.sort.each do |category|
        csv << ['']
        csv << [category] unless params[:no_items]
        category_totals = [category + ' Total', '']
        monthly_totals = {}
        transactions[category].keys.sort.each do |item|
          monthly_item_amounts = []
          @months.each do |month|
            amount = (transactions[category][item][month].nil? ? 0 : transactions[category][item][month].collect(&:amount).sum.round(2))
            monthly_item_amounts << amount

            overall_monthly_totals[month] ||= 0
            monthly_totals[month] ||= 0
            monthly_totals[month] += amount
          end
          sum = monthly_item_amounts.sum
          monthly_item_amounts << sum.round(2) << (sum / @months.size).round(2)
          csv << monthly_item_amounts.unshift('', item) unless params[:no_items]
        end
        monthly_sum = monthly_totals.values.sum
        category_totals += monthly_totals.values.map{ |val| val.round(2) } << 
            monthly_sum.round(2) << (monthly_sum / @months.size).round(2)
        csv << category_totals

        overall_monthly_totals.merge!(monthly_totals) { |key, v1, v2| v1 + v2 }
      end
      overall_sum = overall_monthly_totals.values.sum
      overall_totals += overall_monthly_totals.values.map{ |val| val.round(2) } <<
          overall_sum.round(2) << (overall_sum / @months.size).round(2)
      csv << ['']
      csv << overall_totals
    end
  end

  def transactions_monthly
    @per_page = params[:per_page] || 25
  	@portfolio = Portfolio.find(params[:id])
    
    start_date = DateTime.civil( *params.values_at( :year, :month ).map(&:to_i) )
    @month = Date::ABBR_MONTHNAMES[params[:month].to_i]

  	@all_transactions = @portfolio.transactions.includes(:item, :source, :payment_type)
                      .where({ date_transacted: start_date..(start_date + 1.month - 1.second)})
    
    @transactions = @all_transactions
  											.order(sort_column + " " + sort_direction)
  										    .paginate(page: params[:page], per_page: @per_page)

    @total_spend = @all_transactions.sum(:amount)
  end

  def manage
  	@portfolio = current_user.portfolio
  	@category = Category.new
  	@source = Source.new
  end

  def update
  	if current_user.portfolio.update_attributes(portfolio_params)
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
  	if @portfolio.save
  		flash[:success] = 'Portfolio successfully updated'
  	else
  		flash[:error] = 'Failed to update portfolio'
  	end

  	redirect_to setup_items_url
  end

  def setup_items
  	@categories = current_user.portfolio.categories.paginate(page: params[:page], per_page: 1)
  end

  def split_transaction
    @portfolio = current_user.portfolio
    transaction = @portfolio.transactions.find(params[:id])
    @transactions = [transaction, transaction.dup] unless transaction.nil?
  end

  private

  	def check_setup
  		redirect_to 'setup' unless current_user.portfolio.setup_complete?
  		# also need to check categories?
  	end

    def portfolio_params
      params.require(:portfolio).permit(:name, categories_attributes: [:id, :name, :_destroy, items_attributes: [:id, :name, :_destroy] ],
        transactions_attributes: [:id, :item_id, :source_id, :payment_type_id, :date_transacted, :amount, :notes, :edit_mode, :validated, :_destroy])
    end

    def sort_column
      Transaction.column_names.include?(params[:sort]) ? params[:sort] : "date_transacted"
    end
  
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    def current_year
      @year = params[:year].nil? ? Date.today.year : params[:year].to_i
    end

    def no_items
      @no_items = params[:no_items]
      Rails.logger.debug "no items? #{@no_items}"
    end

end
