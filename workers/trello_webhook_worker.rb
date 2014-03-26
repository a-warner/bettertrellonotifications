class TrelloWebhookWorker < Struct.new(:body)
  def perform
    hook = Trello::ApiObject.new(JSON.parse(body))

    card = hook.get('action', 'data', 'card') || {}
    card['board'] = hook.get('action', 'data', 'board')

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
      old_description = hook.get('action', 'data', 'old', 'desc')

      if old_description.to_s.length.zero? && card['desc'].to_s.length.nonzero?
        User.find_each do |u|
          u.notify_description_added(creator, card)
        end
      end
    end
  end
end
