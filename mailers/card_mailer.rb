class CardMailer < ActionMailer::Base
  include ActionView::Helpers::UrlHelper

  def created(user, creator, card)
    @creator, @card = creator, card

    headers 'Message-ID' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "#{subject_for_card(card)}",
      to: user.email,
      reply_to: email_reply_to_for_card(card),
      content_type: 'text/html'
  end

  def added_description(user, creator, card)
    @creator, @card = creator, card

    headers 'In-Reply-To' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      to: user.email,
      reply_to: email_reply_to_for_card(card),
      content_type: 'text/html'
  end

  def added_comment(user, creator, card, comment)
    @creator, @card, @comment = creator, card, comment

    headers 'In-Reply-To' => message_id_for(card)

    mail from: creator_email(creator),
      subject: "Re: #{subject_for_card(card)}",
      to: user.email,
      reply_to: email_reply_to_for_card(card),
      content_type: 'text/html'
  end

  private

  delegate :sanitize, to: 'ActionView::Base.white_list_sanitizer'
  def markdown_to_html(text)
    sanitize(GitHub::Markdown.render_gfm(text)).html_safe
  end
  helper_method :markdown_to_html

  def creator_email(creator)
    %{"#{creator.fullName}" <#{creator.username}@#{email_domain}>}
  end

  def message_id_for(card)
    "<#{card.id}@#{email_domain}>"
  end

  def subject_for_card(card)
    "[#{card.board.name}] #{card.name}"
  end

  def card_link(card, link_text = card.name)
    link_to(link_text, "https://trello.com/c/#{card.shortLink}")
  end
  helper_method :card_link

  def email_reply_to_for_card(card)
    "#{card.shortLink}@#{email_domain}"
  end
end
