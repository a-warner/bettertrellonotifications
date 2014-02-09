class TrelloIdentity < ActiveRecord::Base
  belongs_to :user

  serialize :omniauth_data

  def client
    @client ||= Trello.new(Trello.key, credentials.token, credentials.secret)
  end

  def username
    omniauth_data.info.nickname
  end

  delegate :credentials, to: :omniauth_data
end
