#!/usr/bin/env ruby

require './PingMessageCommand'
require './TestMessageCommand'

class TwitchMessageCommander
  def initialize
    @commands = [
      PingMessageCommand.new,
      TestMessageCommand.new
    ]
  end

  def call producer, ircMessage
    if producer.nil?
      return
    end

    message = ircMessage.strip
    messageParts = message.split(' ', 3)
    messageType = messageParts[1]

    puts "Handling message: #{message}"

    @commands.each do |command|
      puts "Checking match for #{command.class.name}"
      if command.match? messageType, message
        puts "Matched message: #{message}"
        command.call producer, messageType, message
      end
    end

    producer.deliver_messages
  end
end
