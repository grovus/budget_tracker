class TransactionsController < ApplicationController
  def new
    @portfolio = current_user.portfolio
  	@transaction = Transaction.new
    respond_to do |format|
      format.html # new.html.erb
      format.js # new.js.erb
    end
  end

  def create
  	@item = Item.find(params[:transaction][:item_id])
  	@transaction = @item.transactions.build(transaction_params)
  	if @transaction.save
  		flash[:success] = "Transaction '#{@transaction.item.name} / #{@transaction.source.name}' successfully added to portfolio"
      respond_to do |format|
        format.html { redirect_to current_user.portfolio and return }
        format.js { render 'new.js.erb' and return }
      end
  	else
  		@transaction.errors.each do |attr, message|
          flash[:error] ||= message
      end
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
    respond_to do |format|
      if @transaction.update_attributes(transaction_params)
        flash[:success] = "Transaction updated"
        format.html { redirect_to @portfolio }
        format.json { render json: @transaction }
      else
        format.html { render 'edit' }
        format.json { respond_with_bip(@transaction) }
      end  	  
    end
  end

  def edit_multiple
    transaction_ids = params[:transaction_ids]
    unless transaction_ids.nil?
      if params[:commit].start_with? 'Delete'
        flash[:success] = "deleted #{params[:transaction_ids].size} transactions"
        Transaction.destroy(transaction_ids)
        redirect_to :back and return
      elsif params[:commit].start_with? 'Validate'
        flash[:success] = "validated #{params[:transaction_ids].size} transactions"
        Transaction.update_all({ validated: true }, { id: transaction_ids })
        redirect_to :back and return        
      end
    end
    @portfolio = current_user.portfolio
    transaction_ids ||= @portfolio.transactions.where(condition(params[:edit_type].to_sym)).collect(&:id)
    @transactions = Transaction.find(transaction_ids)
    Transaction.update_all({ edit_mode: true }, { id: transaction_ids })
 
    @current = session[:current_editable] = 1
    @total = session[:total_editable] = @transactions.size

    if params[:edit_individual]
      @transaction = @transactions.first
      render 'edit_individual' and return if @transaction
    end 
  end

  def update_multiple
    @transactions = Transaction.update(params[:transaction_ids].keys, 
        params[:transaction_ids].values).reject { |p| p.errors.empty? }
    if @transactions.empty?
      flash[:notice] = "Transactions updated"
      redirect_to current_user.portfolio
    else
      render 'edit_multiple'
    end    
  end

  def edit_individual
    @portfolio = current_user.portfolio
    #@transaction = Transaction.new
  end

  def update_individual
    @portfolio = current_user.portfolio
    if params[:commit].start_with? 'Cancel'
      @portfolio.transactions.update_all(edit_mode: false)
      session[:current_editable] = nil
      session[:total_editable] = nil
    else
      @transaction = Transaction.find(params[:transaction][:id])

      # this should change once Transaction is refactored
      split_count = 0
      splits = params[:transaction][:split_transactions]
      unless splits.nil?
        amounts = splits.values.collect { |val| val[:amount] }
        amounts << params[:transaction][:amount]
        if !@transaction.validate_split_amounts(amounts) 
          render 'edit_individual' and return
        end

        splits.keys.each do |key|
          trans_params = splits[key]
          next if trans_params['_destroy'] == "1"

          # need to be able to validate this group of transactions against one another and their parent
          # ie. the child amounts should sum to the amount of the parent
          # also, set errors on each (will likely only work once refactored as a nested association)
          if Transaction.create(trans_params.except(:_destroy).permit!)
            split_count += 1
          end
        end
      end

      if @transaction.update_attributes(transaction_params)
        flash[:success] = "Transaction updated"
        flash[:success] += " and created #{split_count} splits" if split_count > 0
      end
    end

    @transaction = contains_editable
    redirect_to transaction_imports_path and return unless @transaction

    @current = session[:current_editable] += 1 
    @total = session[:total_editable]

    render 'edit_individual'
  end

  def split
    @portfolio = current_user.portfolio
    @transaction = @portfolio.transactions.find(params[:id])
  end

  def index
    @portfolio = current_user.portfolio
    @transactions = @portfolio.transactions.all
  end

  def import
    Transaction.import(params[:file])
    redirect_to current_user.portfolio
  end

  def unreconciled
    @portfolio = current_user.portfolio
    @transactions = @portfolio.transactions.where(condition(:unreconciled))
  end

  def duplicated
    @portfolio = current_user.portfolio
    @transactions = @portfolio.transactions.where(condition(:duplicated))
    @transaction_dups = @portfolio.transactions.find(@transactions.collect(&:suspected_dupe_id))
  end


  private

    def transaction_params
    	params.require(:transaction).permit(:amount, :item_id, :source_id, :payment_type_id, :date_transacted, :income, :recurring, :notes, :validated, :edit_mode, :_destroy)
    end

    def contains_unreconciled
      current_user.portfolio.transactions.where(validated: false).first
    end

    def contains_editable
      current_user.portfolio.transactions.find_by_edit_mode(true)
    end

    def condition(param)
      Rails.logger.debug "Edit param : #{param}"
      if param == :imported
        { last_imported: true }
      elsif param == :unreconciled
        { validated: false }
      elsif param == :duplicated
        'suspected_dupe_id is not null'
      else
        true
      end
    end

end
