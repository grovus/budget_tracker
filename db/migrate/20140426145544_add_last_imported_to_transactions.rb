class AddLastImportedToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :last_imported, :boolean
  end
end
