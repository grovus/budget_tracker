class AddBlacklistedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :blacklisted, :boolean
    add_index :transactions, :blacklisted
  end
end
