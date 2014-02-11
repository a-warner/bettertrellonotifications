class MakeTrelloIdentitiesUniqueByUid < ActiveRecord::Migration
  def up
    change_column :trello_identities, :uid, :string, null: false
    remove_index :trello_identities, :uid
    add_index :trello_identities, :uid, unique: true
  end

  def down
    change_column :trello_identities, :uid, :string, null: true
    remove_index :trello_identities, :uid
    add_index :trello_identities, :uid
  end
end
