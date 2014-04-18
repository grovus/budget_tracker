class SourcesController < ApplicationController
  
  helper_method :sort_column, :sort_direction

  def new
  	@source = Source.new
  end

  def create
  	@source = current_user.portfolio.sources.build(source_params)
  	if @source.save
  		flash[:success] = "Succesfully created source #{params[:source][:name]}"
  		redirect_back_or manage_url
  	else
  		#flash[:error] = "Ruhroh, not successed"
  		render 'new'
  	end
  end

  def edit_selected
  	@source = Source.find(params[:source][:id]) 
  	if (params[:commit] == 'Delete')
  		@source.destroy
        flash[:success] = "Source '#{@source.name}' deleted"
        redirect_back_or manage_url
  	end
  end

  def update
 	  @source = Source.find(params[:id])
  	if @source.update_attributes(source_params)
  		flash[:success] = "Source '#{@source.name}' successfully updated"
  		redirect_back_or manage_url
  	else
  		render 'edit_selected'
  	end    
  end

  def show
    @transactions = current_user.portfolio.transactions.where({ source_id: params[:id] })
                        .order(sort_column + " " + sort_direction)
                        .paginate(page: params[:page], per_page: 25)
  end


  private

    def source_params
    	params.require(:source).permit(:name)
    end

    def sort_column
      Transaction.column_names.include?(params[:sort]) ? params[:sort] : "date_transacted"
    end
  
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

end
