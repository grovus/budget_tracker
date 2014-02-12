class TransactionsController < ApplicationController
  def new
  	@transaction = Transaction.new
  end

  def create
  	@item = Item.find(params[:transaction][:item_id])
  	@transaction = @item.transactions.build(transaction_params)
  	if @transaction.save
  		flash[:success] = 'Transaction successfully added to portfolio'
  	else
  		flash[:error] = 'Ruhroh, not successing'
  	end
  	redirect_to current_user.portfolio
  end

  private

    def transaction_params
    	params.require(:transaction).permit(:amount, :item_id, :source_id, :date_transacted, :income, :notes)
    end
end
