class AddEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.text :mailgun_data, null: false

      t.timestamps
    end
  end
end
