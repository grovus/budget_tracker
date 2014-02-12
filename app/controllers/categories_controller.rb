class CategoriesController < ApplicationController

  def new
  	@category = Category.new
  end

  def create
  	@category = current_user.portfolio.categories.build(category_params)
  	if @category.save
  		flash[:success] = 'Category successfully created'
  		redirect_back_or manage_url
  	else
  		render 'new'
  	end
  end

  def edit_selected
  	@category = Category.find(params[:category][:id]) 
  	if (params[:commit] == 'Delete')
  		@category.destroy
        flash[:success] = "Category deleted"
  		redirect_back_or manage_url
  	end
  end

  def update
 	@category = Category.find(params[:id])
  	if @category.update_attributes(category_params)
  		flash[:success] = "Category successfully updated"
  		redirect_back_or manage_url
  	else
  		render 'edit_selected'
  	end  
  end

  def index
  	@categories = current_user.portfolio.categories
  end

  def show
  end

  private

    def category_params
      params.require(:category).permit(:name, items_attributes: [:id, :name, :_destroy])
    end
end
