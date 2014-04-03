class AddIndexToCategoriesName < ActiveRecord::Migration
  def change
  	add_index :categories, [:name, :portfolio_id], unique: true
  end
end
