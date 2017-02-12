#!/usr/bin/env ruby

require './TwitchMessageCommand'

class PingMessageCommand < TwitchMessageCommand
  def match? messageType, message
    messageParts = message.strip.split(' ', 3)
    return messageParts[0] == 'PING'
  end

  def call producer, messageType, message
    puts "Sending PONG"
    messageParts = message.strip.split(' ', 2)
    responseMessage = messageParts[1]
    producer.produce "PONG #{responseMessage}", topic: 'outgoing-messages'
  end
end
