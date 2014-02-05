class Trello
  class << self
    extend Forwardable

    def_delegators :client, :my_boards, :webhooks, :remove_webhook
  end

  InvalidWebhook = Class.new(StandardError)

  include HTTParty
  base_uri 'https://api.trello.com/1'

  def initialize(key, token, secret)
    @key, @token, @secret = key, token, secret
  end

  ['get', 'post', 'put', 'delete'].each do |m|
    define_method(m) { |*args| trello_request(m, *args) }
  end

  def verify_webhook!(body, callback_url, signature)
    raise InvalidWebhook unless Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, body + callback_url)) == signature
  end

  def my_boards
    JSON.parse(get('/members/me/boards'))
  end

  def webhooks
    JSON.parse(Trello.client.get("/tokens/#{Trello.client.send(:token)}/webhooks"))
  end

  def remove_webhook(webhook)
    delete("/webhooks/#{webhook['id']}")
  end

  def self.client
    @client ||= new(ENV.fetch('TRELLO_KEY'), ENV.fetch('TRELLO_TOKEN'), ENV.fetch('TRELLO_SECRET'))
  end

  private
  attr_reader :key, :token, :secret

  def trello_request(method, path, options = {})
    options[:query] = options.fetch(:query, {}).merge(key: key, token: token)
    self.class.send(method, path, options).body
  end
end
