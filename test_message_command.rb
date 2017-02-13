#!/usr/bin/env ruby

require './twitch_message_command'

class TestMessageCommand < TwitchMessageCommand
  def match? messageType, message
    unless messageType.eql? "PRIVMSG"
      return
    end
    messageParts = message.strip.split(' ', 3)
    nick = messageParts[0].split('!', 2)[0][1..-1]
    meta = messageParts[2].split(' :', 2)
    msg = meta[1]
    return nick == "vaeix" && msg == "!test"
  end

  def call producer, messageType, message
    messageParts = message.strip.split(' ', 3)
    meta = messageParts[2].split(' :', 2)
    channel = meta[0]

    puts "Sending test response"
    producer.produce ":vaeixbot!vaeixbot@vaeixbot.tmi.twitch.tv PRIVMSG #{channel} :Successful test!", topic: "outgoing-messages"
  end
end
