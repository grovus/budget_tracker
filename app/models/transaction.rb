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

  #default_scope { where(blacklisted: true) }

  scope :expenses, -> { where(income: false) }
  # TODO: refactor Category to add expense field to differentiate b/w income/expense categories
  #scope :expenses, -> { joins({item: :category}).where(categories: { expense: true }) }

  scope :income, -> { where(income: true) }

  scope :earliest, -> { minimum(:date_transacted) }

  scope :between_dates, -> (start_date, end_date) {
    start_date = earliest if start_date.blank?
    end_date = Time.now if end_date.blank?
    where(date_transacted: start_date..end_date)
  }

  scope :between_amounts, -> (min_amount, max_amount) {
    max_amount = maximum(:amount) if max_amount.blank?
    where(amount: min_amount.to_i..max_amount.to_i)
  }

  scope :find_duplicate_amount_in_range, ->(amount, date, range) {
    constraint = arel_table[:amount].eq(amount).or(arel_table[:original_amount].eq(amount)) 
    between_dates(date - range.days, date + range.days).where(constraint) 
    #between_dates(date - range.days, date + range.days).where('amount = ? OR original_amount = ?', amount, amount) 
  }

  def self.full_select()
    select( "transactions.*, items.name as item_name, categories.name as category_name, sources.name as source_name").joins({item: :category}, :source)
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
    split_transaction.context_key = nil # wipe the ctx key so as not to confuse future imports
    split_transaction.parent_id = self[:id]
    split_transaction
  end

  def validate_split_amounts(amounts)
    amounts_sum = amounts.sum(&:to_f)
    if self[:original_amount] != amounts_sum
      Rails.logger.debug amounts
      errors.add(:amount, 
        "Split amounts (#{helpers.number_to_currency(amounts_sum)}) must equal original transaction amount of #{helpers.number_to_currency(self[:original_amount])}")
      return false
    elsif amounts.size != amounts.uniq.size
      errors.add(:amount, "Split amounts must be unique")
      return false
    end

    true
  end

  def self.itemz_collection(user)
    Item.includes(:category).where(categories: {portfolio_id: user.portfolio.id}).order('categories.name').map{ |i| [i.id, i.full_name] }
  end

  def items_collection
    Item.includes(:category).where(categories: {portfolio_id: item.category.portfolio_id}).map{ |i| [i.id, i.full_name] }
  end

  def self.sourcez_collection(user)
    Source.where(portfolio_id: user.portfolio.id).order(:name).map{ |s| [s.id, s.name] }
  end

  def source_collection
    Source.where(portfolio_id: item.category.portfolio_id).order(:name).map{ |s| [s.id, s.name] }
  end

  def helpers
    ActionController::Base.helpers
  end

  def self.searchable_attributes
    column_names & ["notes", "ref_code", "item_id", "source_id", "payment_type_id", "tax_credit", "income", "blacklisted"]
  end

  def self.field_where(field, keyword, match_like)
    scope = self
    table = self.arel_table
    if searchable_attributes.include? field
      if field.ends_with? "_id"
        assoc = field.split("_id")[0]
        table = assoc.classify.constantize.arel_table

        names = self.reflect_on_association(assoc.to_sym).klass.column_names & ['name']
        field = names[0] if names
        scope = scope.joins(assoc.to_sym)
      end
      scope = scope.where(table[field.to_sym].matches( match_like ? "%#{keyword}%" : "#{keyword}" ))
    end
    scope
  end

  def self.fieldz_where(field, keyword)
    scope = self
    if searchable_attributes.include? field
      if field.ends_with? "_id"
        assoc = field.split("_id")[0] 
        names = self.reflect_on_association(assoc.to_sym).klass.column_names & ["name"]
        field = assoc.pluralize + '.' + names[0] if names
        scope = scope.joins(assoc.to_sym)
      end
      scope = scope.where("#{field} LIKE ?", "%#{keyword}%")
    end
    scope
  end

  #def destroy
    #imported transactions are blacklisted instead of destroyed
  #  if self.import_id && self.context_key
  #    Rails.logger.debug("Blacklisting #{self.context_key}")
  #    self.blacklisted = true
  #    self.save
  #  else
  #    super
  #  end
  #end

end