#!/usr/bin/env ruby

class TwitchMessageCommand
  def match? message_type, message
    return false
  end

  def call producer, message_type, message
    return nil
  end
end
