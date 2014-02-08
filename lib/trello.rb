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
    define_method(m) { |*args| trello_request(ActiveSupport::StringInquirer.new(m), *args) }
  end

  def verify_webhook!(body, callback_url, signature)
    normalized_payload = (body + callback_url).unpack('U*').pack('c*')
    raise InvalidWebhook unless Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret, normalized_payload)) == signature
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

  def post_comment(card_id, comment_text)
    post("/cards/#{card_id}/actions/comments", body: { text: comment_text })
  end

  class << self
    def key
      ENV.fetch('TRELLO_KEY')
    end

    def token
      ENV.fetch('TRELLO_TOKEN')
    end

    def secret
      ENV.fetch('TRELLO_SECRET')
    end

    def client
      @client ||= new(key, token, secret)
    end
  end

  private
  attr_reader :key, :token, :secret

  def trello_request(method, path, options = {})
    where_to_insert_creds = (method.get? || method.delete?) ? :query : :body

    options[where_to_insert_creds] = options.fetch(where_to_insert_creds, {}).merge(key: key, token: token)
    response = self.class.send(method, path, options)

    raise Error.new(response) unless response.ok?

    response.body
  end
end
