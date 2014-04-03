class AddPaymentTypeRefToTransactions < ActiveRecord::Migration
  def change
    add_reference :transactions, :payment_type, index: true
  end
end
