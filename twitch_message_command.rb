#!/usr/bin/env ruby

require './command_permissions_service'

class TwitchMessageCommand
  def initialize
    puts "Setting up base command"
    permissionsHash = Hash.new { Hash.new }

    permissionsHash[:vaeix] = Hash.new
    permissionsHash[:vaeix][:test_command] = true
    permissionsHash[:vaeix][:mp_command] = true

    permissionsHash[:mp646] = Hash.new
    permissionsHash[:mp646][:mp_command] = true

    puts "Hashes build, creating service"
    @permissions_service = CommandPermissionsService.new permissionsHash
  end

  def match? message_type, message
    return false
  end

  def call producer, message_type, message
    return nil
  end

  def hasPermission? permission, message
    return @permissions_service.check permission, message unless @permissions_service.nil?
    return false
  end

  def respond producer, channel, message
    producer.produce ":vaeixbot!vaeixbot@vaeixbot.tmi.twitch.tv PRIVMSG #{channel} :#{message}", topic: "outgoing-messages"
    producer.deliver_messages
  end
end
