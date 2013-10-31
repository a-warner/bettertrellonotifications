ActionMailer::Base.view_paths = File.expand_path "../../views", __FILE__

ActionMailer::Base.raise_delivery_errors = true

if ENV['RACK_ENV'] == 'production'
  # something
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = { }
else
  ActionMailer::Base.add_delivery_method(:letter_opener, LetterOpener::DeliveryMethod, :location => File.expand_path('../../tmp/letter_opener', __FILE__))
  ActionMailer::Base.delivery_method = :letter_opener
end
