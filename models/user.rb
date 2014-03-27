class User < ActiveRecord::Base
  has_many :emails, :class_name => 'UserEmail', dependent: :destroy
  has_one :trello_identity, dependent: :destroy
  alias_method :trello, :trello_identity
  delegate :username, :client, to: :trello, prefix: true, allow_nil: true

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
    transaction do
      trello_identity.try(:destroy)

      authorize_email!(omniauth.info.email)

      create_trello_identity! do |t|
        t.uid = omniauth.uid
        t.omniauth_data = omniauth
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

  def authorize_email!(email_address)
    UserEmail.where(email: email_address).
              where("user_id <> ?", id).
              first.try(:destroy)

    emails.where(email: email_address).first_or_create!.reprocess_emails
  end

  def notify_comment_on_card(creator, card, comment)
    return unless wants_to_be_notified_about?(creator, card, comment)

    CardMailer.delay.added_comment(self, creator, card, comment)
  end

  def notify_card_created(creator, card)
    return unless wants_to_be_notified_about?(creator, card)

    CardMailer.delay.created(self, creator, card)
  end

  def notify_description_added(creator, card)
    return unless wants_to_be_notified_about?(creator, card)

    CardMailer.delay.added_description(self, creator, card)
  end

  def email
    trello_identity.try(:email) || emails.order(:id).first.try(:email) || (raise "User has no email")
  end

  private

  def wants_to_be_notified_about?(creator, card, comment = nil)
    return if is_trello_user?(creator)

    wants_notifications_for_everything_on_board?(card.board) ||
      comment_mentions_user?(comment) ||
      user_assigned_to_card?(card)
  end

  def wants_notifications_for_everything_on_board?(board)
    email_preferences[board.id].present?
  end

  def comment_mentions_user?(comment)
    return unless trello_identity.present?

    comment =~ /(^|[^\w\d])@#{trello_identity.username}([^\w\d]|$)/
  end

  def user_assigned_to_card?(card)
    return unless trello_identity.present?

    card.idMembers.any? { |id| id == trello_identity.uid }
  end

  def is_trello_user?(creator)
    creator['username'] == trello_username
  end
end
