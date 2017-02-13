#!/usr/bin/env ruby

require './twitch_message_command'

class PingMessageCommand < TwitchMessageCommand
  def match? messageType, message
    messageParts = message.strip.split(' ', 3)
    unless messageParts[0] == 'PING'
      puts "Not a ping"
    end
    return messageParts[0] == 'PING'
  end

  def call producer, messageType, message
    puts "Sending PONG"
    messageParts = message.strip.split(' ', 2)
    responseMessage = messageParts[1]
    producer.produce "PONG #{responseMessage}", topic: 'outgoing-messages'
  end
end
