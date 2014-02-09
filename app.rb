require 'rubygems'
require 'bundler/setup'
require 'active_record'
Bundler.require

Dotenv.load
ENV['RACK_ENV'] ||= 'development'

set :database_file, File.join(File.dirname(__FILE__), 'config', 'database.yml')

['config', 'lib', 'models', 'mailers'].each do |path|
  Dir[File.dirname(__FILE__)+"/#{path}/*.rb"].each { |file| require file }
end

trello = Trello.client

use OmniAuth::Builder do
  provider :trello,
           Trello.key,
           Trello.secret,
           app_name: 'BetterTrelloNotifications',
           scope: 'read,write,account',
           expiration: 'never'
end

helpers do
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by_id(session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end
end

get '/' do
  erb :root
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

post "/emails/mailgun" do
  Mailgun.verify_webhook!(params)
  Email.create!(mailgun_data: params.reject { |k, v| k.to_s.starts_with?('attachment-') })

  'OK'
end

get '/emails/authorize' do
  email = Email.verifier.verify(params[:email])

  if user_signed_in? && current_user.has_authed_trello?
    current_user.authorize_email!(email)
    "Ok, you're all set"
  else
    session[:email] = email
    redirect to('/auth/trello')
  end
end

%w(get post).each do |method|
  send(method, '/auth/trello/callback') do
    if user = User.find_by_email(session[:email])
      user.associate_trello_auth!(env['omniauth.auth'])
    else
      user = User.find_or_create_from_omniauth!(env['omniauth.auth'])
    end

    session[:user_id] = user.id

    user.authorize_email!(session.delete(:email)) if session[:email]

    "Ok, you're all set"
  end
end

get '/auth/failure' do
  params[:message]
end

get '/sign_out' do
  session.delete(:user_id)

  redirect to('/')
end

get '/sign_in' do
  if user_signed_in?
    redirect to('/')
  else
    redirect to('/auth/trello')
  end
end

error Trello::InvalidWebhook, Mailgun::InvalidSignature do
  logger.error "Webhook couldn't be verified!"
  status 400
end
