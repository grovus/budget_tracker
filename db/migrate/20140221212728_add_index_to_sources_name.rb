class AddIndexToSourcesName < ActiveRecord::Migration
  def change
  	add_index :sources, [:name, :portfolio_id], unique: true
  end
end
