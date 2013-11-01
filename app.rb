require 'rubygems'
require 'bundler/setup'
Bundler.require

Dotenv.load
ENV['RACK_ENV'] ||= 'development'

['config', 'lib', 'mailers'].each do |path|
  Dir[File.dirname(__FILE__)+"/#{path}/*.rb"].each { |file| require file }
end

get '/' do
  "Hello, world"
end

head '/webhook' do
end

post '/webhook' do
  puts params.inspect
  hook = Map.new(JSON.parse(request.body.read))
  puts hook.inspect

  card = hook.get('action', 'data', 'card')
  card['board'] = hook.get('action', 'data', 'board')

  creator = hook.get('action', 'memberCreator')

  case hook.get('action', 'type')
  when 'commentCard'
    comment = hook.get('action','data','text').to_s

    CardMailer.added_comment(creator, card, comment).deliver
  when 'createCard'
    CardMailer.created(creator, card).deliver
  when 'updateCard'
    old_description = hook.get('action', 'data', 'old', 'desc')

    if (old_description || '').length.zero?
      CardMailer.added_description(creator, card).deliver
    end
  end
end
