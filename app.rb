require 'rubygems'
Bundler.require

Dotenv.load

class Trello
  include HTTParty
  base_uri 'https://api.trello.com/1'

  def initialize(key, token)
    @key, @token = key, token
  end

  def get(path, options = {})
    options[:query] = options.fetch(:query, {}).merge(key: key, token: token)
    self.class.get(path, options).body
  end

  private
  attr_reader :key, :token
end

# https://trello.com/1/authorize?key=<my_key>&name=trello_mentions&scope=read&expiration=never&response_type=token
trello = Trello.new(ENV.fetch('TRELLO_KEY'), ENV.fetch('TRELLO_TOKEN'))

get '/' do
  "Hello, world"
end
