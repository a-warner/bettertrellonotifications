class CardMailer < ActionMailer::Base
  default from: "no-reply@#{ENV.fetch('EMAIL_DOMAIN')}"


  def created(creator, card, to_address)
    @creator, @card = creator, card
    mail to: to_address,
      subject: "[#{card.board.name}] #{card.name}",
      content_type: 'text/html'
  end
end
