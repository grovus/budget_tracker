class AddPortfolioRefToSources < ActiveRecord::Migration
  def change
    add_reference :sources, :portfolio, index: true
  end
end
