puts "Bettertrellonotifications console up!"

def reload!
  Pry.save_history if Pry.config.history.should_save
  exec File.expand_path('../console', __FILE__)
end
