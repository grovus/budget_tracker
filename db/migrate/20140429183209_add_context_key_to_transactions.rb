class AddContextKeyToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :context_key, :string
    add_index :transactions, :context_key
  end
end
