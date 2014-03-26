class CreateTrelloBoards < ActiveRecord::Migration
  def change
    create_table :trello_boards do |t|
      t.string :trello_id, null: false
      t.string :webhook_id, null: false

      t.timestamps null: false
    end

    add_index :trello_boards, :webhook_id
    add_index :trello_boards, :trello_id, unique: true
  end
end
