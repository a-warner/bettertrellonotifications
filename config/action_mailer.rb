ActionMailer::Base.view_paths = File.expand_path "../../views", __FILE__

ActionMailer::Base.raise_delivery_errors = true

ActionMailer::Base.class_eval do
  extend Delayed::DelayMail

  def self.email_domain
    ENV.fetch('EMAIL_DOMAIN')
  end
  delegate :email_domain, to: 'self.class'

  default from: "no-reply@#{email_domain}",
          to: ENV.fetch('EMAIL_TO_ADDRESS')
end

if ENV['RACK_ENV'] == 'production'
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.smtp_settings = {
      :authentication => :plain,
      :address => ENV.fetch('MAILGUN_SMTP_SERVER'),
      :port => ENV.fetch('MAILGUN_SMTP_PORT'),
      :domain => ENV.fetch('MAILGUN_DOMAIN'),
      :user_name => ENV.fetch('MAILGUN_SMTP_LOGIN'),
      :password => ENV.fetch('MAILGUN_SMTP_PASSWORD')
  }
else
  ActionMailer::Base.add_delivery_method(:letter_opener, LetterOpener::DeliveryMethod, :location => File.expand_path('../../tmp/letter_opener', __FILE__))
  ActionMailer::Base.delivery_method = :letter_opener
end
