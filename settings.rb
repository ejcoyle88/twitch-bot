#!/usr/bin/env ruby

require 'yaml'

class Settings
  attr_reader :channel, :irc_uri, :irc_port, :irc_nickname, :irc_password,
    :kafka_client_id, :kafka_seed_brokers

  def initialize
    settings = YAML::load_file("config/application.yml")
    @channel = settings[:channel]
    @irc_uri = settings[:irc_uri]
    @irc_port = settings[:irc_port]
    @irc_nickname = settings[:irc_nickname]
    @irc_password = settings[:irc_password]
    @kafka_client_id = settings[:kafka_client_id]
    @kafka_seed_brokers = settings[:kafka_seed_brokers]
  end
end
