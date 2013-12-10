require 'rubygems'
require 'bundler/setup'
Bundler.require

Dotenv.load
ENV['RACK_ENV'] ||= 'development'

['config', 'lib', 'mailers'].each do |path|
  Dir[File.dirname(__FILE__)+"/#{path}/*.rb"].each { |file| require file }
end

trello = Trello.client

get '/' do
  "Ok"
end

head '/webhook' do
end

post '/webhook' do
  logger.info params.inspect

  body = request.body.read

  trello.verify_webhook!(body, "http://#{request.env['HTTP_HOST']}#{request.env['PATH_INFO']}", env['HTTP_X_TRELLO_WEBHOOK'])

  hook = Map.new(JSON.parse(body))
  logger.info hook.inspect

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

error Trello::InvalidWebhook do
  logger.error "Webhook couldn't be verified!"
  status 400
end
