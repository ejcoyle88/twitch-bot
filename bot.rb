#!/usr/bin/env ruby

require 'kafka'

require './irc_connection'
require './twitch_message_commander'

class Bot
  def initialize settings
    @target_channel = settings.channel
    @irc_uri = settings.irc_uri
    @irc_port = settings.irc_port
    @irc_nickname = settings.irc_nickname
    @irc_password = settings.irc_password
    @stop_running = false

    @kafka = Kafka.new(
      seed_brokers: settings.kafka_seed_brokers,
      client_id: settings.kafka_client_id
    )
  end

  def create_write_thread
    return Thread.new do
      @outgoing_kafka_consumer = @kafka.consumer(
        group_id: "outgoing-chat-consumer",
        offset_commit_interval: 5,
        offset_commit_threshold: 100
      )

      @outgoing_kafka_consumer.subscribe "outgoing-messages", start_from_beginning: false

      @outgoing_kafka_consumer.each_message do |message|
        if @stop_running
          break
        end
        @irc_connection.send message.value
      end
    end
  end

  def create_command_processing_thread
    return Thread.new do
      commander = TwitchMessageCommander.new

      @command_kafka_consumer = @kafka.consumer(
        group_id: "command-chat-consumer",
        offset_commit_interval: 5,
        offset_commit_threshold: 100
      )

      @command_kafka_consumer.subscribe "incoming-messages", start_from_beginning: false

      @command_kafka_consumer.each_message do |message|
        if @stop_running
          break
        end
        commander.call @kafka_producer, message.value
      end
    end
  end

  def setup_irc_connection
    puts "#{@irc_uri}, #{@irc_port}, #{@irc_nickname}, #{@irc_password}"
    @irc_connection = IrcConnection.new @irc_uri, @irc_port, @irc_nickname, @irc_password
    @irc_connection.connect
    @irc_connection.send "PASS oauth:#{@irc_password}\r\nNICK #{@irc_nickname}\r\n"
    @irc_connection.send "JOIN #{@target_channel}"
  end

  def read_from_twitch
    puts "Setting up kafka producer"
    @kafka_producer = @kafka.producer

    messages_received = 0
    until @irc_connection.socket.eof? do
      if @stop_running
        break
      end

      message = @irc_connection.socket.gets
      messages_received += 1
      puts "Received from twitch: #{message}"

      unless message.nil? || message == "" 
        @kafka_producer.produce(message, topic: "incoming-messages")
        @kafka_producer.deliver_messages
      end
    end
  end

  def run
    trap("INT") { quit }
    trap("QUIT") { quit }

    setup_irc_connection

    @threads = [
      create_write_thread,
      create_command_processing_thread
    ]

    @threads.each {|t| t.abort_on_exception = true}

    read_from_twitch
  end

  def quit
    puts "Shutting down"
    @stop_running = true
    @irc_connection.send "QUIT"
    puts "Killing kafka producer"
    @kafka_producer.shutdown unless @kafka_producer.nil?
    puts "Killing outgoing kafka consumer"
    @outgoing_kafka_consumer.stop unless @outgoing_kafka_consumer.nil?
    puts "Killing command kafka consumer"
    @command_kafka_consumer.stop unless @command_kafka_consumer.nil?
    @threads.each(&:join)
  end
end
