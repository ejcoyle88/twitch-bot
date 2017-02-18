#!/usr/bin/env ruby

class CommandPermissionsService
  def initialize permissions
    @permissions = permissions
  end

  def check permission, message
    messageParts = message.strip.split(' ', 3)
    nick = messageParts[0].split('!', 2)[0][1..-1]
    puts nick
    @permissions[nick.to_sym].key? permission
  end
end
