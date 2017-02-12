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
    unless producer.nil?
      return
    end

    message = ircMessage.strip
    messageParts = message.split(' ', 3)
    messageType = messageParts[1]

    @commands.each do |command|
      command.call producer, messageType, message
    end

    producer.deliver_messages
  end
end
