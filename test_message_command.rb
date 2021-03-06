#!/usr/bin/env ruby

require './twitch_message_command'

class TestMessageCommand < TwitchMessageCommand
  def initialize
    super()
  end

  def match? messageType, message
    return unless messageType.eql? "PRIVMSG"
    return unless hasPermission?(:test_command, message)
    messageParts = message.strip.split(' ', 3)
    meta = messageParts[2].split(' :', 2)
    msg = meta[1]
    return msg == "!test"
  end

  def call producer, messageType, message
    messageParts = message.strip.split(' ', 3)
    meta = messageParts[2].split(' :', 2)
    channel = meta[0]

    puts "Sending test response"
    respond producer, channel, "Successful test!"
  end
end
