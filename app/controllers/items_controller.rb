class ItemsController < ApplicationController

  before_action :store_location, only: [:create, :update]

  helper_method :sort_column, :sort_direction

  def new
  	@item = Item.new
  end

  def create
  	@item = current_user.portfolio.items.build(item_params)
  	if @item.save
  		flash[:success] = "Item successfully created"
  		redirect_to session[:referrer_page]
  	else
  		render 'new'
  	end
  end

  def index
  end

  def edit
  	@item = Item.find(params[:id])
  end

  def edit_selected
  	@item = Item.find(params[:item][:id]) 
  end

  def update
  	@item = Item.find(params[:id])
  	if @item.update_attributes(item_params)
  		flash[:success] = "Item successfully updated"
  		redirect_to session[:referrer_page]
  	else
  		render 'edit_selected'
  	end
  end

  def show
   @transactions = current_user.portfolio.transactions.where({ item_id: params[:id] })
                        .order(sort_column + " " + sort_direction)
                        .paginate(page: params[:page], per_page: 25)
  end

  private

    def item_params
    	params.require(:item).permit(:name, :category_id)
    end

    def sort_column
      Transaction.column_names.include?(params[:sort]) ? params[:sort] : "date_transacted"
    end
  
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end    
end
