class CardMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper

  EMAIL_DOMAIN = ENV.fetch('EMAIL_DOMAIN')

  default from: "no-reply@#{EMAIL_DOMAIN}",
          to: ENV.fetch('EMAIL_TO_ADDRESS')


  def created(creator, card)
    @creator, @card = creator, card

    headers 'Message-ID' => message_id_for(card)

    mail subject: "#{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_description(creator, card)
    @creator, @card = creator, card

    headers 'In-Reply-To' => message_id_for(card)

    mail from: unique_creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_comment(creator, card, comment)
    @creator, @card, @comment = creator, card, comment

    headers 'In-Reply-To' => message_id_for(card)

    mail from: unique_creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  private

  def unique_creator_email(creator)
    "#{creator.username}@#{EMAIL_DOMAIN}"
  end

  def message_id_for(card)
    "<#{card.id}@#{EMAIL_DOMAIN}>"
  end

  def subject_for_card(card)
    "[#{card.board.name}] #{card.name}"
  end

  def card_link(card, link_text = card.name)
    link_to(link_text, "https://trello.com/c/#{card.shortLink}")
  end
  helper_method :card_link
end
