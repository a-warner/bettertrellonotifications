class TrelloWebhookWorker < Struct.new(:body)
  def perform
    hook = Map.new(JSON.parse(body))

    card = hook.get('action', 'data', 'card')
    card['board'] = hook.get('action', 'data', 'board')

    creator = hook.get('action', 'memberCreator')

    case hook.get('action', 'type')
    when 'commentCard'
      comment = hook.get('action','data','text').to_s

      CardMailer.added_comment(creator, card, comment).deliver
    when 'createCard'
      CardMailer.created(creator, card).deliver
    when 'updateCard'
      old_description = hook.get('action', 'data', 'old', 'desc')

      if old_description.to_s.length.zero? && card['desc'].to_s.length.nonzero?
        CardMailer.added_description(creator, card).deliver
      end
    end
  end
end
