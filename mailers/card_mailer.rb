class CardMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper

  default from: "no-reply@#{ENV.fetch('EMAIL_DOMAIN')}",          to: ENV.fetch('EMAIL_TO_ADDRESS')


  def created(creator, card)
    @creator, @card = creator, card
    mail subject: "[#{card.board.name}] #{card.name}",
      content_type: 'text/html'
  end

  def added_description(creator, card)
    @creator, @card = creator, card
    mail subject: "Re: [#{card.board.name}] #{card.name}",
      content_type: 'text/html'
  end

  private

  def card_link(card)
    link_to(card.name, "https://trello.com/c/#{card.shortLink}")
  end
  helper_method :card_link
end
