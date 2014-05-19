# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140519135713) do

  create_table "categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "income"
    t.integer  "portfolio_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories", ["name", "portfolio_id"], name: "index_categories_on_name_and_portfolio_id", unique: true
  add_index "categories", ["portfolio_id"], name: "index_categories_on_portfolio_id"

  create_table "items", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["category_id"], name: "index_items_on_category_id"
  add_index "items", ["name", "category_id"], name: "index_items_on_name_and_category_id", unique: true

  create_table "payment_types", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "portfolios", force: true do |t|
    t.string   "name"
    t.datetime "date_created"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "portfolios", ["name", "user_id"], name: "index_portfolios_on_name_and_user_id", unique: true
  add_index "portfolios", ["user_id"], name: "index_portfolios_on_user_id"

  create_table "sources", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "portfolio_id"
  end

  add_index "sources", ["name", "portfolio_id"], name: "index_sources_on_name_and_portfolio_id", unique: true
  add_index "sources", ["portfolio_id"], name: "index_sources_on_portfolio_id"

  create_table "transactions", force: true do |t|
    t.datetime "date_transacted"
    t.float    "amount"
    t.boolean  "credit"
    t.boolean  "income"
    t.boolean  "recurring"
    t.integer  "frequency"
    t.datetime "date_started"
    t.datetime "date_completed"
    t.integer  "item_id"
    t.integer  "source_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "notes"
    t.integer  "payment_type_id"
    t.integer  "import_id"
    t.boolean  "last_imported"
    t.string   "context_key"
    t.boolean  "validated",         default: true
    t.string   "ref_code"
    t.integer  "suspected_dupe_id"
    t.boolean  "edit_mode",         default: false
    t.float    "original_amount"
    t.integer  "parent_id"
    t.boolean  "tax_credit"
  end

  add_index "transactions", ["context_key"], name: "index_transactions_on_context_key"
  add_index "transactions", ["date_transacted", "amount", "item_id", "source_id", "payment_type_id", "import_id"], name: "transactions_index", unique: true
  add_index "transactions", ["edit_mode"], name: "index_transactions_on_edit_mode"
  add_index "transactions", ["import_id"], name: "index_transactions_on_import_id"
  add_index "transactions", ["item_id"], name: "index_transactions_on_item_id"
  add_index "transactions", ["payment_type_id"], name: "index_transactions_on_payment_type_id"
  add_index "transactions", ["ref_code"], name: "index_transactions_on_ref_code"
  add_index "transactions", ["source_id"], name: "index_transactions_on_source_id"
  add_index "transactions", ["suspected_dupe_id"], name: "index_transactions_on_suspected_dupe_id"
  add_index "transactions", ["validated"], name: "index_transactions_on_validated"

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "password_digest"
    t.string   "remember_token"
    t.boolean  "admin",           default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["remember_token"], name: "index_users_on_remember_token"

end
