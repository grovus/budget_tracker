class AddSuspectedDupeIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :suspected_dupe_id, :integer
    add_index :transactions, :suspected_dupe_id
  end
end
