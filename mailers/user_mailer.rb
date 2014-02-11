class UserMailer < ActionMailer::Base
  include UrlHelper
  helper_method :url_with_path

  def requires_trello_authorization(email_id)
    @email = Email.find(email_id)

    mail to: @email.from,
      subject: 'We need you to authorize your trello account',
      content_type: 'text/html'
  end
end
