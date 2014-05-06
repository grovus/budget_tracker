class AddValidatedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :validated, :boolean, default: true
    add_index :transactions, :validated
  end
end
