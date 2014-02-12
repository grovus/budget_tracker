class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.datetime :date_transacted
      t.float :amount
      t.boolean :credit
      t.boolean :income
      t.boolean :recurring
      t.integer :frequency
      t.datetime :date_started
      t.datetime :date_completed
      t.references :item, index: true
      t.references :source, index: true

      t.timestamps
    end
  end
end
