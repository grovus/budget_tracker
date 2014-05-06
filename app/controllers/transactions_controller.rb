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
    @portfolio = current_user.portfolio
  	@transaction = Transaction.find(params[:id])
  	if @transaction.update_attributes(transaction_params)
  	  flash[:success] = "Transaction updated"
  	  redirect_to @portfolio and return #unless contains_invalid
      #@transaction = Transaction.find(200)
  	end
  	  
    render 'edit'
  end

  def edit_multiple
    unless params[:transaction_ids].nil?
      if params[:commit].start_with? 'Delete'
        flash[:success] = "deleted #{params[:transaction_ids].size} transactions"
        Transaction.destroy(params[:transaction_ids])
        redirect_to current_user.portfolio
      end
    end
    # retrieve the active list of not-yet-validated transactions
    @portfolio = current_user.portfolio
    @transactions = Transaction.find(params[:transaction_ids])
    Transaction.update_all({ edit_mode: true }, { id: params[:transaction_ids] })
 
    if params[:edit_individual]
      @transaction = contains_editable
      render 'edit_individual' and return if @transaction
    end 
  end

  def update_multiple
    @transactions = Transaction.update(params[:transaction_ids].keys, params[:transaction_ids].values).reject { |p| p.errors.empty? }
    if @transactions.empty?
      flash[:notice] = "Transactions updated"
      redirect_to current_user.portfolio
    else
      render 'edit_multiple'
    end    
  end

  def edit_individual
  end

  def update_individual
    @portfolio = current_user.portfolio
    if params[:commit].start_with? 'Cancel'
      @portfolio.transactions.update_all(edit_mode: false)
    else
      @transaction = Transaction.find(params[:transaction][:id])
      if @transaction.update_attributes(transaction_params)
        flash[:success] = "Transaction updated"
      end
    end

    @transaction = contains_editable
    redirect_to transaction_imports_path and return unless @transaction
    
    render 'edit_individual'
  end

  def index
    @portfolio = current_user.portfolio
    @transactions = Transaction.all.limit(1)

    @transactions.each do |t|
      @transaction = t
      render 'edit'
    end
  end

  def import
    Transaction.import(params[:file])
    redirect_to current_user.portfolio
  end

  private

    def transaction_params
    	params.require(:transaction).permit(:amount, :item_id, :source_id, :payment_type_id, :date_transacted, :income, :recurring, :notes, :validated, :edit_mode)
    end

    def contains_invalid
      current_user.portfolio.transactions.where(validated: false).first
    end

    def contains_editable
      current_user.portfolio.transactions.find_by_edit_mode(true)
    end
end
