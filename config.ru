require './app'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => ENV.fetch('COOKIE_SECRET')
use Rack::Flash

map '/' do
  run Sinatra::Application
end

map '/delayed_job' do
  use CurrentUserMustBeAdmin

  run DelayedJobWeb
end
