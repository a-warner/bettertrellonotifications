class Email < ActiveRecord::Base
  serialize :mailgun_data, Hash

  after_create :process
  before_validation :set_from, on: :create

  class_attribute :verifier
  self.verifier = ActiveSupport::MessageVerifier.new(ENV.fetch('EMAIL_VERIFIER_SECRET'))

  scope :unprocessed, -> { where(processed: false) }

  validates :from, presence: true

  def subject
    mailgun_data['Subject']
  end

  def body_text
    mailgun_data['stripped-text'].presence || mailgun_data['body-plain']
  end

  def to
    mailgun_data['To']
  end

  def sending_user
    @sending_user ||= User.find_by_email(parse_email_address(from))
  end

  def to_address_local_part
    parse_email_address(to).split('@').first
  end

  def process
    return if processed?

    if sending_user.try(:has_authed_trello?)
      transaction do
        update!(processed: true)
        sending_user.process_email(self)
      end
    else
      UserMailer.delay.requires_trello_authorization(self.id)
    end
  rescue ActiveRecord::StaleObjectError
  end
  handle_asynchronously :process

  def parse_email_address(address)
    address[/\A(\S+)\z/, 1] || address[/<(\S+)>/, 1]
  end

  private

  def set_from
    self.from = parse_email_address(mailgun_data['from']).downcase
  end
end