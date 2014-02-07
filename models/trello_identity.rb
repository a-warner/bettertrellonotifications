class TrelloIdentity < ActiveRecord::Base
  belongs_to :user

  serialize :omniauth_data
end
