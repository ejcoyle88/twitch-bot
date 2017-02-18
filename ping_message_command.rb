#!/usr/bin/env ruby

require './twitch_message_command'

class PingMessageCommand < TwitchMessageCommand
  def match? message_type, message
    message_parts = message.strip.split(' ', 3)
    return message_parts[0] == 'PING'
  end

  def call producer, message_type, message
    puts "Sending PONG"
    message_parts = message.strip.split(' ', 2)
    response_message = message_parts[1]
    producer.produce "PONG #{response_message}", topic: 'outgoing-messages'
  end
end
