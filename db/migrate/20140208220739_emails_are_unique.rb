class EmailsAreUnique < ActiveRecord::Migration
  def change
    remove_index :user_emails, :email
    add_index :user_emails, :email, unique: true
  end
end
