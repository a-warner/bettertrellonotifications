class User < ActiveRecord::Base
  has_many :emails, :class_name => 'UserEmail'
  has_one :trello_identity

  def self.find_or_create_from_omniauth!(omniauth)
    if identity = TrelloIdentity.where(uid: omniauth.uid).first
      identity.user
    else
      transaction do
        create!.tap do |u|
          u.emails.where(email: omniauth.info.email).first_or_create
          u.create_trello_identity do |t|
            t.uid = omniauth.uid
            t.omniauth_data = omniauth
          end
        end
      end
    end
  end
end
