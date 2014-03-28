class TrelloWebhookWorker < Struct.new(:body)
  def perform
    hook = Trello::ApiObject.new(JSON.parse(body))

    if card_short = hook.get('action', 'data', 'card')
      card = Trello.client.get_card(card_short['id'])
      card['board'] = hook.get('action', 'data', 'board')
      card['shortLink'] = card_short['shortLink']
    end

    creator = hook.get('action', 'memberCreator')

    case hook.get('action', 'type')
    when 'commentCard'
      comment = hook.get('action','data','text').to_s

      User.find_each do |u|
        u.notify_comment_on_card(creator, card, comment)
      end
    when 'createCard'
      User.find_each do |u|
        u.notify_card_created(creator, card)
      end
    when 'updateCard'
      old_data = hook.get('action', 'data', 'old')
      return unless old_data.try(:key?, 'desc')

      if old_data['desc'].to_s.length.zero? && card['desc'].to_s.length.nonzero?
        User.find_each do |u|
          u.notify_description_added(creator, card)
        end
      end
    end
  end
end
