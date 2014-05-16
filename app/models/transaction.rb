class Transaction < ActiveRecord::Base
  belongs_to :item
  belongs_to :source
  belongs_to :payment_type
  belongs_to :portfolio

  after_initialize :set_defaults

  validates :amount, presence: true, numericality: true, 
      uniqueness: { scope: [:date_transacted, :item_id, :source_id, :payment_type_id, :import_id], message: 'Transaction must be unique' }
  validates :date_transacted, presence: true
  validates :item_id, presence: true
  validates :source_id, presence: true
  validates :payment_type_id, presence: true

  scope :find_duplicate_amount_in_range, ->(amount, date, range) { 
    where('amount = ? AND date_transacted BETWEEN ? AND ?', amount, date - range.days, date + range.days) }

  def self.full_select()
    select( "transactions.*, items.name as item_name, categories.name as category_name")
  end

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
    self[:item_id] ||= Item.find_by(name: 'Unknown').id
    self[:source_id] ||= Source.find_by(name: 'Unknown').id
  end

  def split
    self[:original_amount] ||= self[:amount] 
    split_transaction = dup
    split_transaction.parent_id = self[:id]
    split_transaction
  end

  def validate_split_amounts(amounts)
    amounts_sum = amounts.sum(&:to_f) + self[:amount]
    if self[:original_amount] != amounts_sum
      Rails.logger.debug amounts
      errors.add(:amount, "Split amounts (#{number_to_currency(amounts_sum)}) must equal original transaction amount of #{number_to_currency(self[:original_amount])}")
      return false
    elsif amounts.size != amounts.uniq.size
      errors.add(:amount, "Split amounts must be unique")
      return false
    end

    true
  end
end
