class User < ActiveRecord::Base
  has_many :emails, :class_name => 'UserEmail', dependent: :destroy
  has_one :trello_identity, dependent: :destroy
  alias_method :trello, :trello_identity
  delegate :username, :client, to: :trello, prefix: true

  def self.find_or_create_from_omniauth!(omniauth)
    if identity = TrelloIdentity.where(uid: omniauth.uid).first
      identity.user
    else
      transaction do
        create!.tap do |u|
          u.associate_trello_auth!(omniauth)
        end
      end
    end
  end

  def associate_trello_auth!(omniauth)
    authorize_email!(omniauth.info.email)

    create_trello_identity do |t|
      t.uid = omniauth.uid
      t.omniauth_data = omniauth
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

  def authorize_email!(email_address)
    UserEmail.where(email: email_address).
              where("user_id <> ?", id).
              first.try(:destroy)

    emails.where(email: email_address).first_or_create!.reprocess_emails
  end
end
