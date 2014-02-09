class AddFromColumnToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :from, :string, null: false
    add_index :emails, :from

    add_column :emails, :processed, :boolean, null: false, default: false
  end
end
