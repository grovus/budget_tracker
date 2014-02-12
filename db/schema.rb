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

ActiveRecord::Schema.define(version: 20140130193949) do

  create_table "categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "income"
    t.integer  "portfolio_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "categories", ["portfolio_id"], name: "index_categories_on_portfolio_id"

  create_table "items", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "items", ["category_id"], name: "index_items_on_category_id"

  create_table "portfolios", force: true do |t|
    t.string   "name"
    t.datetime "date_created"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "portfolios", ["user_id"], name: "index_portfolios_on_user_id"

  create_table "sources", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "portfolio_id"
  end

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
  end

  add_index "transactions", ["item_id"], name: "index_transactions_on_item_id"
  add_index "transactions", ["source_id"], name: "index_transactions_on_source_id"

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
