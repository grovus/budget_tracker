class SourcesController < ApplicationController
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

  private

    def source_params
    	params.require(:source).permit(:name)
    end
end
