module Mailgun
  extend self

  InvalidSignature = Class.new(StandardError)

  def verify_webhook!(params)
    raise InvalidSignature unless params['signature'] == calculate_signature(params)
  end

  def calculate_signature(params)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha256'),
                            ENV.fetch('MAILGUN_API_KEY'),
                            '%s%s' % [params['timestamp'], params['token']])
  end
end
