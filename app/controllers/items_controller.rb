class ItemsController < ApplicationController

  before_action :store_location, only: [:create, :update]

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

  private

    def item_params
    	params.require(:item).permit(:name, :category_id)
    end
end
