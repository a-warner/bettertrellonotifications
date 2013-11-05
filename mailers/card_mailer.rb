class CardMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper

  EMAIL_DOMAIN = ENV.fetch('EMAIL_DOMAIN')

  default from: "no-reply@#{EMAIL_DOMAIN}",
          to: ENV.fetch('EMAIL_TO_ADDRESS')


  def created(creator, card)
    @creator, @card = creator, card

    headers 'Message-ID' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "#{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_description(creator, card)
    @creator, @card = creator, card

    headers 'In-Reply-To' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  def added_comment(creator, card, comment)
    @creator, @card, @comment = creator, card, comment

    headers 'In-Reply-To' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      content_type: 'text/html'
  end

  private

  delegate :sanitize, to: 'ActionView::Base.white_list_sanitizer'
  delegate :fragment, to: 'Nokogiri::HTML'
  def markdown_to_html(text)
    html = RDiscount.new(text, :smart, :autolink).to_html

    sanitize(fragment(html).to_html).html_safe
  end
  helper_method :markdown_to_html

  def creator_email(creator)
    %{"#{creator.fullName}" <#{creator.username}@#{EMAIL_DOMAIN}>}
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
