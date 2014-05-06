class AddEditModeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :edit_mode, :boolean, default: false
    add_index :transactions, :edit_mode
  end
end
