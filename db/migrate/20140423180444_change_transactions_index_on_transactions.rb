class ChangeTransactionsIndexOnTransactions < ActiveRecord::Migration
  def change
  	remove_index :transactions, name: 'transactions_index'
  	add_index :transactions, [:date_transacted, :amount, :item_id, :source_id, :payment_type_id, :import_id], unique: true, name: 'transactions_index'
  end
end
