class AddTaxCreditToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :tax_credit, :boolean
  end
end
