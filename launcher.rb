#!/usr/bin/env ruby

require './bot'
require './settings'

class Application
  def run
    settings = Settings.new
    puts "Starting up"
    bot = Bot.new settings
    bot.run
  end
end

app = Application.new
app.run
