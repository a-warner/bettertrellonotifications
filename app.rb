require 'rubygems'
require 'bundler/setup'
Bundler.require

Dotenv.load
ENV['RACK_ENV'] ||= 'development'

set :database_file, File.join(File.dirname(__FILE__), 'config', 'database.yml')

['config', 'lib', 'models', 'mailers'].each do |path|
  Dir[File.dirname(__FILE__)+"/#{path}/*.rb"].each { |file| require file }
end

trello = Trello.client

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => ENV.fetch('COOKIE_SECRET')

use OmniAuth::Builder do
  provider :trello,
           Trello.key,
           Trello.secret,
           app_name: 'BetterTrelloNotifications',
           scope: 'read,write,account',
           expiration: 'never'
end

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

%w(get post).each do |method|
  send(method, '/auth/trello/callback') do
    User.find_or_create_from_omniauth!(env['omniauth.auth'])

    "Done"
  end
end

get '/auth/failure' do
  params[:message]
end

error Trello::InvalidWebhook do
  logger.error "Webhook couldn't be verified!"
  status 400
end
