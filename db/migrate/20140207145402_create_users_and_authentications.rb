class CreateUsersAndAuthentications < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.timestamps
    end

    create_table :user_emails do |t|
      t.string :email
      t.belongs_to :user

      t.timestamps
    end

    add_index :user_emails, :user_id
    add_index :user_emails, :email

    create_table :trello_identities do |t|
      t.belongs_to :user
      t.string :uid
      t.text :omniauth_data

      t.timestamps
    end

    add_index :trello_identities, :user_id
    add_index :trello_identities, :uid
  end
end
