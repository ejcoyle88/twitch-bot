#!/usr/bin/env ruby

require './ping_message_command'
require './test_message_command'
require './mp_message_command'

class TwitchMessageCommander
  def initialize
    @commands = [
      PingMessageCommand.new,
      TestMessageCommand.new,
      MpMessageCommand.new
    ]
  end

  def call producer, irc_message
    return if producer.nil?

    message = irc_message.strip
    message_parts = message.split(' ', 3)
    message_type = message_parts[1]

    puts "Handling message: #{message}"

    @commands.each do |command|
      puts "Checking match for #{command.class.name}"
      if command.match? message_type, message
        puts "Matched message: #{message}"
        command.call producer, message_type, message
      end
    end
  end
end
