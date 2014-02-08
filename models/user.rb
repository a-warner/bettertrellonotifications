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

  def self.find_by_email(email)
    UserEmail.find_by_email(email).try(:user)
  end

  def has_authed_trello?
    trello_identity.present?
  end

  def process_email(email)
    raise "Not authed" unless has_authed_trello?

    trello_client.post_comment(email.to_address_local_part, email.body_text)
  end

  def trello_client
    trello_identity.client
  end
end
