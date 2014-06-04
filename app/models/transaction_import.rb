class TransactionImport
  include ActiveModel::Model

  attr_accessor :file_name
  #TODO : make import_type a model with attributes for default_payment_type, banking vs credit card etc.
  attr_accessor :import_type

  validates :file_name,  presence: true
  validates :import_type, presence: true

  def self.fields_amex
  	[	{ name: 'date_transacted', type: 'date'}, 
  		{ name: 'transaction_ref', type: 'string'},
  		{ name: 'debit', type: 'number'},
  		{ name: 'context_key', type: 'string'},
  		{ name: 'unused_1', type: 'string'},
  		{ name: 'unused_2', type: 'string'}
  	]
  end

  def self.fields_td
  	[	{ name: 'date_transacted', type: 'date'}, 
  		{ name: 'context_key', type: 'string'},
  		{ name: 'debit', type: 'number'},
  		{ name: 'credit', type: 'number'},
  		{ name: 'balance', type: 'number'}
  	]
  end

  def self.fields
  	fields_td
  end

  def self.field_names
  	fields.map { |val| val[:name] }
  end

  def self.field_types
  	fields.map { |val| val[:type] }
  end

  def self.field_type_for(field_name)
  	field = fields.detect { |val| val[:name] == field_name }
  	field[:type] unless field.nil?
  end

  def fields
  	@import_type == "Amex" ? TransactionImport.fields_amex : TransactionImport.fields_td
  end

  def field_names
  	fields.map { |val| val[:name] }
  end

  def self.import_types
     ["TD Chequing", "TD Visa", "Amex"]
  end

  def self.import_type_defaults
    { "Amex" => "Amex", "TD Visa" => "Visa", "TD Chequing" => "PAC"}
  end

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def banking?
    @import_type == "TD Chequing"
  end

  def save
  	if valid? && imported_transactions.size > 0 && imported_transactions.map(&:valid?).all?
  		imported_transactions.each(&:save!)
  		true
  	else
  		imported_transactions.each_with_index do |tx, index|
  			tx.errors.full_messages.each do |message|
  				errors.add :base, "Row #{index+1} : #{message}"
  			end
  		end
  		false
  	end
  end

  def imported_transactions
  	@imported_transactions ||= (import || [])
  end

  def import
    return if !valid?
    transactions = []
    CSV.foreach(@file_name.path) do |line|      
      if line.size != field_names.size
      	errors.add :base, 
          "Incorrect file format. Found #{line.size} fields instead of #{TransactionImport.field_names.size}. #{line}..."
        return
      end

      row = Hash[[field_names, line].transpose]

      # check for credit line items
      amount = row["debit"] || row["credit"] 
      #next unless row["amount"] && !(row["amount"].starts_with? '-')
      
      date = Date.strptime(row["date_transacted"], "%m/%d/%Y")

      # look to see if transaction was already imported
      import_id = capture_import_id(row)
      next if Transaction.find_by_import_id(import_id)
      Rails.logger.debug "Processing Import ID -> #{import_id}"

      # look for transaction with this amount in the given date range
      suspected_dupe = Transaction.find_duplicate_amount_in_range(row["amount"], date, 5).first
      Rails.logger.debug "Found suspected duplicate transaction -> #{suspected_dupe.id}" if suspected_dupe

      # create new tx
      tx = Transaction.new
      # for suspected dupes, write the tx id on the new tx so can be verified by user
      tx.suspected_dupe_id = suspected_dupe.id unless suspected_dupe.nil?
      tx.last_imported = true
      tx.import_id = import_id
      tx.date_transacted = date

      tx.income = row["debit"].nil? && banking?
      tx.credit = !tx.income && (row["debit"].nil? || row["debit"].starts_with?('-'))
      amount = -amount if tx.credit && amount > 0

      tx.amount = amount
      tx.original_amount = amount
      tx.notes = row["context_key"].squish
      tx.payment_type = find_payment_type(row["context_key"])
      tx.ref_code = strip_ref_code(row)
      tx.context_key = sanitize_context_key(row["context_key"])
    
      # look for matching tx with same context key and copy source/category
      Rails.logger.debug "Looking for context '#{row["context_key"]}'"
      match = Transaction.find_by_context_key(tx.context_key)
      if match 
      	Rails.logger.debug("Found context match!!! #{match.id}, #{match.item.id}")
        tx.item = match.item
        tx.source = match.source
        tx.tax_credit = match.tax_credit
        tx.blacklisted = match.blacklisted
        # copy notes if amounts are the same as it's likely a recurring expense
        tx.notes = match.notes if tx.amount == match.amount
      else
        Rails.logger.debug "No match found #{match}"
      	# create new Item and/or Source?
        tx.item = Item.find_by_name("Unknown")
        tx.source = match_source(row["context_key"])
      end
            
      tx.validated = false
      
      Rails.logger.debug(row)

      transactions << tx
    end

    transactions.sort_by { |t| t.date_transacted }
  end

  def find_payment_type(val)
  	if val.include? "CHQ"
  		PaymentType.find_by_name("Cheque")
  	elsif val.include? "TFR"
  		PaymentType.find_by_name("Transfer")
  	elsif val.include? "W/D"
  		PaymentType.find_by_name("Cash")
    elsif val.ends_with? "PAY"
      PaymentType.find_by_name("Pay")
  	elsif val.index /([A-Z][\d]){3}$/
  		PaymentType.find_by_name("DirectPayment")
  	# could have another for Interac but difficult to determine
  	# basically, the only pattern is that 'val' *might* contain a vendor
  	else
  		PaymentType.find_by_name(TransactionImport.import_type_defaults[import_type])
  	end
  end

  def sanitize_context_key(val)
  	start_idx = (val.index /([A-Z]{2}[\d]{3})/)
  	start_idx = start_idx ? start_idx + 5 : 0 
  	end_idx = (val.index /\s((([A-Z][\d]){3})|([\d]{6}))$/) || val.length
  	val[start_idx..end_idx-1].squish
  end

  def strip_ref_code(row)
  	if @import_type == "Amex"
  		row["transaction_ref"]
  	else
  		match = row["context_key"].match /^([A-Z]{2}[\d]{3})|\s((([A-Z][\d]){3})|([\d]{6}))$/
  		match[0].squish unless match.nil?
  	end
  end

  def match_source(val)
    #Source.new(name: val, validated: false)
  	Source.name_contains(val.split(/[ \/]/)[0]).first || Source.find_by_name("Unknown")
  end

  def capture_import_id(row)
  	if @import_type == "Amex"
  		ref_code = strip_ref_code(row)
		  idx = ref_code.index /[0-9]+/ unless ref_code.nil?
		  ref_code[idx..-1].squish.to_i unless idx.nil?
	  else
      (row["balance"].to_f * 100).to_i + Date.strptime(row["date_transacted"], "%m/%d/%Y").to_time.to_i
    end
  end
end