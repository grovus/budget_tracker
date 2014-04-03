class AddIndexToTransactions < ActiveRecord::Migration
  def change
  	add_index :transactions, [:date_transacted, :amount, :item_id, :source_id], unique: true, name: 'transactions_index'
  end
end
