#!/usr/bin/env ruby

require 'yaml'

class Settings
  attr_reader :channel, :ircUri, :ircPort, :ircNickname, :ircPassword,
    :kafkaClientId, :kafkaSeedBrokers

  def initialize
    settings = YAML::load_file("config/application.yml")
    @channel = settings[:channel]
    @ircUri = settings[:ircUri]
    @ircPort = settings[:ircPort]
    @ircNickname = settings[:ircNickname]
    @ircPassword = settings[:ircPassword]
    @kafkaClientId = settings[:kafka_client_id]
    @kafkaSeedBrokers = settings[:kafka_seed_brokers]
  end
end
