class AddEmailPreferencesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email_preferences, :hstore, null: false, default: ''
  end
end
