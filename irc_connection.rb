#!/usr/bin/env ruby

require 'socket'

class IrcConnection
  attr_reader :socket

  def initialize uri, port, nickname, password
    @uri = uri
    @port = port
    @nickname = nickname
    @password = password
  end

  def send command
    puts command
    @socket.puts command
  end

  def connect
    @socket = TCPSocket.open @uri, @port
  end
end
