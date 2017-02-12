#!/usr/bin/env ruby

class TwitchMessageCommand
  def match? messageType, message
    return false
  end

  def call producer, messageType, message
    return nil
  end
end
