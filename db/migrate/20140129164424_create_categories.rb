class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string :name
      t.string :description
      t.boolean :income
      t.references :portfolio, index: true

      t.timestamps
    end
  end
end
