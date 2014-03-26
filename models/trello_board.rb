class TrelloBoard < ActiveRecord::Base
  validates :trello_id, :webhook_id, presence: true
end
