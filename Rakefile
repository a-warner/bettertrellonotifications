require 'sinatra/activerecord/rake'
require 'delayed/tasks'
require './app'

def hook_board(id, options = {})
  callback_url = File.join(options[:callback_url] || ENV.fetch('CANONICAL_URL'), 'webhook')
  JSON.parse(Trello.client.post('/webhooks', query: { idModel: id, callbackURL: callback_url}))
end

def find_board(board_name)
  Trello.my_boards.detect { |board| board['name'] =~ Regexp.new(board_name, 'i') }
end

namespace 'trello' do
  desc 'List webhooks'
  task 'webhooks' do
    boards = Trello.my_boards.index_by { |b| b['id'] }

    webhooks = Trello.webhooks.each do |hook|
      hook['board_name'] = boards[hook['idModel']].try(:[], 'name')
    end

    pp webhooks
  end

  desc 'List trello member from token'
  task 'whoami' do
    pp JSON.parse(Trello.client.get('/members/me'))
  end

  desc 'List boards for the token user'
  task 'boards' do
    pp Trello.my_boards
  end

  desc 'Create a webhook for idModel'
  task 'hook', [:id_model, :callback_url] do |t, args|
    raise "Need to pass id_model argument" unless args[:id_model]
    pp hook_board(args[:id_model], args.except(:id_model))
  end

  desc 'Create a webhook for Board Name'
  task 'hook_board', [:board_name] do |t, args|
    raise "Need to specify board_name" unless args[:board_name]
    board_name = args[:board_name]

    find_board(board_name).tap do |found_board|
      raise "Couldn't find board that matches #{board_name}" unless found_board

      hook_board(found_board['id'])
      puts "Hooked up #{found_board['name'].inspect}"
    end
  end

  desc 'Unhook a board'
  task 'unhook_board', [:board_name] do |t, args|
    raise "Need to specify board_name" unless args[:board_name]
    board_name = args[:board_name]

    find_board(board_name).tap do |found_board|
      raise "Couldn't find board that matches #{board_name}" unless found_board

      Trello.webhooks.detect { |h| h['idModel'] == found_board['id'] }.tap do |hook|
        if hook
          Trello.remove_webhook(hook)
          puts "Unhooked #{found_board['name'].inspect}"
        else
          puts "No webhook for board #{found_board['name'].inspect}"
        end
      end
    end
  end

  desc 'Hook all boards in organization'
  task 'hook_all', [:organization_id] do |t, args|
    raise "Specify organization_id" unless organization_id = args[:organization_id]

    existing_webhooks = Trello.webhooks.index_by { |h| h['idModel'] }
    JSON.parse(Trello.client.get("/organizations/#{organization_id}/boards")).each do |board|
      unless existing_webhooks[board['id']]
        print "Hooking up #{board['name']}..."
        hook_board(board['id'])
        print "done\n"
      end
    end
  end
end
