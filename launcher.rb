#!/usr/bin/env ruby

require 'yaml'

require './Bot'

class Application
  def run
    settings = YAML::load_file("config/application.yml")
    bot = Bot.new settings
    bot.run
  end
end

app = Application.new
app.run
