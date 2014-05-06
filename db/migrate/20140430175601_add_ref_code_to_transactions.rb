class AddRefCodeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :ref_code, :string
    add_index :transactions, :ref_code
  end
end
