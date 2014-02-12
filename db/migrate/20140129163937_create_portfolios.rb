class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios do |t|
      t.string :name
      t.datetime :date_created
      t.references :user, index: true

      t.timestamps
    end
  end
end
