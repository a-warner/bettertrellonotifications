ActionMailer::Base.view_paths = File.expand_path "../../views", __FILE__

ActionMailer::Base.raise_delivery_errors = true

if ENV['RACK_ENV'] == 'production'
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.smtp_settings = {
      :authentication => :plain,
      :address => "smtp.mailgun.org",
      :port => ENV.fetch('MAILGUN_SMTP_PORT'),
      :domain => ENV.fetch('MAILGUN_DOMAIN'),
      :user_name => ENV.fetch('MAILGUN_SMTP_LOGIN'),
      :password => ENV.fetch('MAILGUN_SMTP_PASSWORD')
  }
else
  ActionMailer::Base.add_delivery_method(:letter_opener, LetterOpener::DeliveryMethod, :location => File.expand_path('../../tmp/letter_opener', __FILE__))
  ActionMailer::Base.delivery_method = :letter_opener
end
