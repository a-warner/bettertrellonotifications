class Trello
  class ApiObject
    yaml_tag "tag:ruby.yaml.org,2002:TrelloApiObject"

    def initialize(attrs = {})
      self.delegate_map = attrs
    end

    def encode_with(coder)
      coder["delegate_map"] = delegate_map
    end

    def init_with(coder)
      self.delegate_map = coder['delegate_map']
    end

    def respond_to_missing?(method, include_all)
      delegate_map.respond_to?(method, include_all)
    end

    private
    attr_reader :delegate_map

    def delegate_map=(attrs)
      @delegate_map = attrs.is_a?(Map) ? attrs.dup : Map.new(attrs)
    end

    def method_missing(method, *args, &block)
      if delegate_map.respond_to?(method, !:include_all)
        ret = delegate_map.__send__(method, *args, &block)
        ret = Trello::ApiObject.new(ret) if ret.is_a?(Map)
        ret
      else
        super
      end
    end
  end

  class << self
    extend Forwardable

    def_delegators :client, :my_boards, :webhooks, :remove_webhook
  end

  InvalidWebhook = Class.new(StandardError)
  Error = Class.new(StandardError)
  PermissionDenied = Class.new(StandardError)

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
    a(get("/tokens/#{Trello.client.send(:token)}/webhooks"))
  end

  def get_board(board_id)
    a(get("/boards/#{board_id}"))
  end

  def get_card(card_id)
    a(get("/cards/#{card_id}"))
  end

  def remove_webhook(webhook)
    delete("/webhooks/#{webhook['id']}")
  end

  def post_comment(card_id, comment_text)
    post("/cards/#{card_id}/actions/comments", body: { text: comment_text })
  end

  def organization_boards(organization_id = ENV.fetch('ORGANIZATION_ID'))
    a(get("/organizations/#{organization_id}/boards"))
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

    unless response.ok?
      case response.code
      when 401
        raise PermissionDenied.new(response)
      else
        raise Error.new(response)
      end
    end

    response.body
  end

  def json_to_api_object(json)
    wrap_parsed_json(JSON.parse(json))
  end
  alias_method :a, :json_to_api_object

  def wrap_parsed_json(parsed_json)
    case parsed_json
    when Array then parsed_json.map { |j| ApiObject.new(j) }
    else ApiObject.new(parsed_json)
    end
  end
end
