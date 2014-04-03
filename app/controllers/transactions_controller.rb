class TransactionsController < ApplicationController
  def new
  	@transaction = Transaction.new
  end

  def create
  	@item = Item.find(params[:transaction][:item_id])
  	@transaction = @item.transactions.build(transaction_params)
  	if @transaction.save
  		flash[:success] = "Transaction '#{@transaction.item.name} / #{@transaction.source.name}' successfully added to portfolio"
  	else
  		@transaction.errors.each do |attr, message|
          flash[:error] ||= message
        end
  		#flash[:error] = 'Ruhroh, not successing'
  	end
  	redirect_to current_user.portfolio
  end

  def destroy
  	@transaction = Transaction.find(params[:id])
  	if current_user?(@transaction.item.category.portfolio.user)
  		@transaction.destroy
  		flash[:success] = "Transaction deleted"
  	else
  		flash[:error] = "Access denied"
  	end
  	redirect_to current_user.portfolio
  end

  def edit
  	@transaction = Transaction.find(params[:id])
  	@portfolio = current_user.portfolio
  end

  def update
  	@transaction = Transaction.find(params[:id])
  	if @transaction.update_attributes(transaction_params)
  	  flash[:success] = "Transaction updated"
  	  redirect_to current_user.portfolio
  	else
  	  @portfolio = current_user.portfolio
  	  render 'edit'
  	end  	
  end

  private

    def transaction_params
    	params.require(:transaction).permit(:amount, :item_id, :source_id, :payment_type_id, :date_transacted, :income, :notes)
    end
end
