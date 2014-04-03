class AddIndexToItemsName < ActiveRecord::Migration
  def change
  	add_index :items, [:name, :category_id], unique: true
  end
end
