class CardMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper

  EMAIL_DOMAIN = ENV.fetch('EMAIL_DOMAIN')

  default from: "no-reply@#{EMAIL_DOMAIN}",
          to: ENV.fetch('EMAIL_TO_ADDRESS')


  def created(creator, card)
    @creator, @card = creator, card
    mail subject: "#{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_description(creator, card)
    @creator, @card = creator, card
    mail subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_comment(creator, card, comment)
    @creator, @card, @comment = creator, card, comment
    mail from: "#{creator.username}@#{EMAIL_DOMAIN}",
      subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  private

  def subject_for_card(card)
    "[#{card.board.name}] #{card.name}"
  end

  def card_link(card, link_text = card.name)
    link_to(link_text, "https://trello.com/c/#{card.shortLink}")
  end
  helper_method :card_link
end
