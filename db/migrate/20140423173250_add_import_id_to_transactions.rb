class AddImportIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :import_id, :integer
    add_index :transactions, :import_id
  end
end
