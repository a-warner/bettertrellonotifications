class CurrentUserMustBeAdmin
  def initialize(app)
    @app = app
  end

  def call(env)
    if User.find_by_id(env['rack.session'][:user_id]).try(:admin?)
      @app.call(env)
    else
      [404, {}, ['404']]
    end
  end
end
