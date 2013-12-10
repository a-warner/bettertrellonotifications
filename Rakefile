require './app'

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
    callback_url = File.join(args[:callback_url] || ENV.fetch('CANONICAL_URL'), 'webhook')
    pp JSON.parse(Trello.client.post('/webhooks', query: { idModel: args[:id_model], callbackURL: callback_url}))
  end

  desc 'Create a webhook for Board Name'
  task 'hook_board', [:board_name] do |t, args|
    raise "Need to specify board_name" unless args[:board_name]
    board_name = args[:board_name]

    Trello.my_boards.detect do |board|
      board['name'] =~ Regexp.new(board_name, 'i')
    end.tap do |found_board|
      raise "Couldn't find board that matches #{board_name}" unless found_board

      puts "Hooking:"
      pp found_board

      Rake::Task['trello:hook'].invoke(found_board['id'])
    end
  end

  desc 'Hook all boards in organization'
  task 'hook_all', [:organization_id] do |t, args|
    raise "Specify organization_id" unless organization_id = args[:organization_id]

    existing_webhooks = Trello.webhooks.index_by { |h| h['idModel'] }
    JSON.parse(Trello.client.get("/organizations/#{organization_id}/boards")).each do |board|
      unless existing_webhooks[board['id']]
        puts "Hooking up #{board['name']}..."
        Rake::Task['trello:hook'].invoke(board['id'])
        puts "...done"
      end
    end
  end
end
