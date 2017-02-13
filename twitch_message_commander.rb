#!/usr/bin/env ruby

require './ping_message_command'
require './test_message_command'

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
