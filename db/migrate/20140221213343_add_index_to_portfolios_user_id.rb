class AddIndexToPortfoliosUserId < ActiveRecord::Migration
  def change
  	add_index :portfolios, [:name, :user_id], unique: true
  end
end
