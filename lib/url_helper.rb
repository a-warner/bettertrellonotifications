module UrlHelper
  extend self

  def canonical_url
    ENV.fetch('CANONICAL_URL')
  end

  def url_with_path(path, options = {})
    Addressable::URI.parse(canonical_url).tap do |u|
      u.path = path
      u.query = options.to_query
    end.to_s
  end
end
