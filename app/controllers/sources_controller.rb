class SourcesController < ApplicationController
  
  helper_method :sort_column, :sort_direction

  def new
  	@source = Source.new

    respond_to do |format|
      format.html # new.html.erb
      format.js # new.js.erb
    end
  end

  def create
  	@source = current_user.portfolio.sources.build(source_params)
  	if @source.save
  		flash[:success] = "Successfully created source #{params[:source][:name]}"

      respond_to do |format|
  		  format.html { redirect_back_or manage_url }
        format.js
      end
  	else
  		render 'new'
  	end
  end

  def edit_selected
  	@source = Source.find(params[:source][:id]) 
  	if (params[:commit] == 'Delete')
  		@source.destroy
      flash[:success] = "Source '#{@source.name}' deleted"
      respond_to do |format|
        format.html { redirect_back_or manage_url }
        format.js { render 'destroy_selected.js.erb' }
      end    
    else
      respond_to do |format|
        format.html
        format.js 
      end    
  	end
  end

  def update
 	  @source = Source.find(params[:id])
  	if @source.update_attributes(source_params)
  		flash[:success] = "Source '#{@source.name}' successfully updated"
      respond_to do |format|
        format.html { redirect_back_or manage_url }
        format.js
      end
    else
  		render 'edit_selected'
  	end    
  end

  def show
    @source_transactions = current_user.portfolio.transactions.where({ source_id: params[:id] })
    @transactions = @source_transactions
                        .order(sort_column + " " + sort_direction)
                        .paginate(page: params[:page], per_page: 25)
    @total_spent = @source_transactions.sum(:amount)
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
