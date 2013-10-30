require 'rubygems'
Bundler.require

Dotenv.load

TRELLO_KEY, TRELLO_SECRET = ENV.fetch('TRELLO_KEY'), ENV.fetch('TRELLO_SECRET')

get '/' do
  "Hello, world"
end
