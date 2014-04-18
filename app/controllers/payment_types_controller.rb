class PaymentTypesController < ApplicationController
  
  helper_method :sort_column, :sort_direction

  def show
    @transactions = current_user.portfolio.transactions.where({ payment_type_id: params[:id] })
                        .order(sort_column + " " + sort_direction)
                        .paginate(page: params[:page], per_page: 25)
  end

  private

    def sort_column
      Transaction.column_names.include?(params[:sort]) ? params[:sort] : "date_transacted"
    end
  
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

end
