class Transaction < ActiveRecord::Base
  belongs_to :item
  belongs_to :source

  validates :amount, presence: true
  validates :date_transacted, presence: true
  validates :item_id, presence: true
  validates :source_id, presence: true
end
