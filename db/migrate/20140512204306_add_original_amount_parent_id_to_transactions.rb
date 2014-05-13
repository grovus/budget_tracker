class AddOriginalAmountParentIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :original_amount, :float
    add_column :transactions, :parent_id, :integer
  end
end
