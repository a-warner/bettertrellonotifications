require 'rubygems'
Bundler.require

Dotenv.load
ENV['RACK_ENV'] ||= 'development'

['config', 'lib', 'mailers'].each do |path|
  Dir[File.dirname(__FILE__)+"/#{path}/*.rb"].each { |file| require file }
end

class Trello
  include HTTParty
  base_uri 'https://api.trello.com/1'

  def initialize(key, token)
    @key, @token = key, token
  end

  ['get', 'post', 'put'].each do |m|
    define_method(m) { |*args| trello_request(m, *args) }
  end

  private
  attr_reader :key, :token

  def trello_request(method, path, options = {})
    options[:query] = options.fetch(:query, {}).merge(key: key, token: token)
    self.class.send(method, path, options).body
  end
end

trello = Trello.new(ENV.fetch('TRELLO_KEY'), ENV.fetch('TRELLO_TOKEN'))

get '/' do
  "Hello, world"
end

head '/webhook' do
end

post '/webhook' do
  puts params.inspect
  hook = Map.new(JSON.parse(request.body.read))

  card = hook.get('action', 'data', 'card')
  card['board'] = hook.get('action', 'data', 'board')

  creator = hook.get('action', 'memberCreator')

  case hook.get('action', 'type')
  when 'commentCard'
    comment = hook.get('action','data','text').to_s
    # email
  when 'createCard'
    CardMailer.created(creator, card).deliver
  when 'updateCard'
    old_description = hook.get('action', 'data', 'old', 'desc')

    if (old_description || '').length.zero?
      CardMailer.added_description(creator, card).deliver
    end
  end

  puts hook.inspect
end
