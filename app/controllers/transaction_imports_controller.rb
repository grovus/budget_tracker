class TransactionImportsController < ApplicationController

	before_action :check_file, only: :create

	def new
  	@transaction_import = TransactionImport.new
  	#@transaction_import.errors.add :base, "Please select a file"
	end

	def create
    # update existing transactions to reset last_imported
  	current_user.portfolio.transactions.update_all(last_imported: false)
  	
  	@transaction_import = TransactionImport.new(params[:transaction_import])
  	if @transaction_import.save
  		@transactions = @transaction_import.imported_transactions
  		#current_user.portfolio.transactions.update_all(last_imported: false)
    		render :imported, 
    			notice: "Imported #{@transaction_import.imported_transactions.size} transactions successfully."
  	else
    		render :new
  	end
	end

	def imported
	end

	def index
		@transactions = Transaction.where(last_imported: true)
		render :imported
	end

  	private

  		def check_file
  			redirect_to new_transaction_import_url(), flash: { error: "Please select a file" } if params[:transaction_import].nil?
#  			redirect_to new_transaction_import_url() if params[:transaction_import].nil?
  		end

end
