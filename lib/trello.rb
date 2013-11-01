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
