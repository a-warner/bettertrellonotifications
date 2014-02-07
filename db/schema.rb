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

ActiveRecord::Schema.define(version: 20140207145402) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "trello_identities", force: true do |t|
    t.integer  "user_id"
    t.string   "uid"
    t.text     "omniauth_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "trello_identities", ["uid"], name: "index_trello_identities_on_uid", using: :btree
  add_index "trello_identities", ["user_id"], name: "index_trello_identities_on_user_id", using: :btree

  create_table "user_emails", force: true do |t|
    t.string   "email"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_emails", ["email"], name: "index_user_emails_on_email", using: :btree
  add_index "user_emails", ["user_id"], name: "index_user_emails_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
