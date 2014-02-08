class Email < ActiveRecord::Base
  serialize :mailgun_data, Hash

  after_create :process

  def subject
    mailgun_data['Subject']
  end

  def body_text
    mailgun_data['stripped-text'].presence || mailgun_data['body-plain']
  end

  def to
    mailgun_data['To']
  end

  def from
    mailgun_data['from']
  end

  def sending_user
    @sending_user ||= User.find_by_email(parse_email_address(from))
  end

  def to_address_local_part
    parse_email_address(to).split('@').first
  end

  def process
    if sending_user.try(:has_authed_trello?)
      sending_user.process_email(self)
    else
      # send auth request
    end
  end
  handle_asynchronously :process

  def parse_email_address(address)
    address[/\A(\S+)\z/, 1] || address[/<(\S+)>/, 1]
  end
end
