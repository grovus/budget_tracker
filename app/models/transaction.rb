class Transaction < ActiveRecord::Base
  belongs_to :item
  belongs_to :source
  belongs_to :payment_type

  after_initialize :set_defaults

  validates :amount, presence: true, numericality: true, 
      uniqueness: { scope: [:date_transacted, :item_id, :source_id, :payment_type_id], message: 'Transaction must be unique' }
  validates :date_transacted, presence: true
  validates :item_id, presence: true
  validates :source_id, presence: true
  validates :payment_type_id, presence: true

  def self.for_year(year)
  	where( "strftime('%Y', date_transacted) = '?'", year )
  end

  def self.for_year_month(year, month)
  	where( "strftime('%Y-%m', date_transacted) = '?-?'", year, month)
  end

  def set_defaults
  	#TODO: set 'smart' defaults for other fields based on frequency of occurrence etc.
  	# or order the select collection appropriately 
    self[:date_transacted] ||= (Transaction.last.date_transacted || Time.now).strftime("%Y-%m-%d")
    self[:payment_type_id] ||= Transaction.last.payment_type_id || PaymentType.find_by(name: 'Visa').id
  end
end
