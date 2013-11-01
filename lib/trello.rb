class Trello
  InvalidWebhook = Class.new(StandardError)

  include HTTParty
  base_uri 'https://api.trello.com/1'

  def initialize(key, token, secret)
    @key, @token, @secret = key, token, secret
  end

  ['get', 'post', 'put'].each do |m|
    define_method(m) { |*args| trello_request(m, *args) }
  end

  def verify_webhook!(body, callback_url, signature)
    raise InvalidWebhook unless Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, body + callback_url)).chomp == signature
  end

  private
  attr_reader :key, :token, :secret

  def trello_request(method, path, options = {})
    options[:query] = options.fetch(:query, {}).merge(key: key, token: token)
    self.class.send(method, path, options).body
  end
end
