class TransactionImport
  include ActiveModel::Model

  attr_accessor :file_name
  attr_accessor :import_type

  validates :file_name,  presence: true

  def self.fields_amex
  	[	{ name: 'date_transacted', type: 'date'}, 
  		{ name: 'transaction_ref', type: 'string'},
  		{ name: 'amount', type: 'number'},
  		{ name: 'context_key', type: 'string'},
  		{ name: 'unused_1', type: 'string'},
  		{ name: 'unused_2', type: 'string'}
  	]
  end

  def self.fields_td
  	[	{ name: 'date_transacted', type: 'date'}, 
  		{ name: 'context_key', type: 'string'},
  		{ name: 'amount', type: 'number'},
  		{ name: 'debit', type: 'number'},
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

  def initialize(attributes = {})
    attributes.each { |name, value| send("#{name}=", value) }
  end

  def persisted?
    false
  end

  def save
  	if imported_transactions.size > 0 && imported_transactions.map(&:valid?).all?
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
  	@imported_transactions ||= import
  end

  def import
    # add logic to determine what type of import this is
    transactions = []

    CSV.foreach(@file_name.path) do |line|
      
      if line.size != field_names.size
      	errors.add :base, "Incorrect file format. Found #{line.size} fields instead of #{TransactionImport.field_names.size}"
      	return transactions
      end

      row = Hash[[field_names, line].transpose]
      # skip for credit line items 
      next unless row["amount"] && !(row["amount"].starts_with? '-')
      
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
      #tx.date_imported = Time.now
      tx.date_transacted = date
      tx.amount = row["amount"]
      tx.original_amount = tx.amount
    
      # look for matching tx with same context key and copy source/category
      match = Transaction.find_by_context_key(row["context_key"])
      if match 
      	Rails.logger.debug("Found context match!!! #{match.id}, #{match.item.id}")
        tx.item = match.item
        tx.source = match.source
        tx.tax_credit = match.tax_credit
        # also copy notes once ref field is added?
      else
      	# create new Item and/or Source?
        tx.item = Item.find_by_name("Unknown")
        tx.source = match_source(row["context_key"])
      end

      tx.payment_type = find_payment_type(row["context_key"])
      tx.notes = row["context_key"].squish
      tx.context_key = sanitize_context_key(row["context_key"])
      tx.ref_code = strip_ref_code(row)
      
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
  	elsif val.index /([A-Z][\d]){3}$/
  		PaymentType.find_by_name("DirectPayment")
  	# could have another for Interac but difficult to determine
  	# basically, the only pattern is that 'val' might contain a vendor
  	else
  		PaymentType.find_by_name(import_type)
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