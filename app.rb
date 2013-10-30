require 'rubygems'
Bundler.require

Dotenv.load

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

  if hook.get('action', 'type') == 'commentCard'
    mentions = Twitter::Extractor.extract_mentioned_screen_names(hook.get('action','data','text').to_s).uniq
  end

  puts hook.inspect
end
