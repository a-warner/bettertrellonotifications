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
    return unless has_access_to?(card)

    CardMailer.added_comment(self, creator, card, comment).deliver
  end
  handle_asynchronously :notify_comment_on_card

  def notify_card_created(creator, card)
    return unless wants_to_be_notified_about?(creator, card)
    return unless has_access_to?(card)

    CardMailer.created(self, creator, card).deliver
  end
  handle_asynchronously :notify_card_created

  def notify_description_added(creator, card)
    return unless wants_to_be_notified_about?(creator, card)
    return unless has_access_to?(card)

    CardMailer.added_description(self, creator, card).deliver
  end
  handle_asynchronously :notify_description_added

  def email
    trello_identity.try(:email) || emails.order(:id).first.try(:email) || (raise "User has no email")
  end

  def visible_boards
    trello_client.organization_boards
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
    return unless comment.present? && trello_identity.present?

    comment =~ /(^|[^\w\d])@#{trello_identity.username}([^\w\d]|$)/
  end

  def user_assigned_to_card?(card)
    return unless trello_identity.present?

    card.idMembers.any? { |id| id == trello_identity.uid }
  end

  def is_trello_user?(creator)
    creator['username'] == trello_username
  end

  def has_access_to?(card)
    return unless trello_identity.present?

    begin
      trello_client.get_card(card.id)
      true
    rescue Trello::PermissionDenied
      false
    end
  end
end
