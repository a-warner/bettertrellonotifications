class AddLockVersionToEmails < ActiveRecord::Migration
  def change
    add_column :emails, :lock_version, :integer, null: false, default: 0
  end
end
