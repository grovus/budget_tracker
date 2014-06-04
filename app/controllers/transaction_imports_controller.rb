class TransactionImportsController < ApplicationController

  before_action :check_params, only: :create

	def new
  	@transaction_import = TransactionImport.new
	end

	def create
    # update existing transactions to reset last_imported
  	current_user.portfolio.transactions.update_all(last_imported: false)
  	
  	@transaction_import = TransactionImport.new(params[:transaction_import])
  	if @transaction_import.save
  		@transactions = @transaction_import.imported_transactions
    	render :imported, notice: "Imported #{@transaction_import.imported_transactions.size} transactions successfully."
  	else
    	render :new
  	end
	end

	def imported
	end

	def index
    @transactions = current_user.portfolio.transactions.full_select.where(last_imported: true)
		render :imported
	end

  	private

  		def check_params
  			#redirect_to new_transaction_import_url(), flash: { error: "Please select a file" } and return if params[:transaction_import][:file_name].blank?
        #redirect_to new_transaction_import_url(), flash: { error: "Please select an import type" } and return if params[:transaction_import][:import_type].blank?
      end

end
