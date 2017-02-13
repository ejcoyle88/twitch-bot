#!/usr/bin/env ruby

require 'kafka'

require './IrcConnection'
require './TwitchMessageCommander'

class Bot
  def initialize settings
    @targetChannel = settings.channel
    @ircUri = settings.ircUri
    @ircPort = settings.ircPort
    @ircNickname = settings.ircNickname
    @ircPassword = settings.ircPassword
    @stopRunning = false

    @kafka = Kafka.new(
      seed_brokers: settings.kafkaSeedBrokers,
      client_id: settings.kafkaClientId
    )
  end

  def createWriteThread
    return Thread.new do
      @outgoingKafkaConsumer = @kafka.consumer(
        group_id: "outgoing-chat-consumer",
        offset_commit_interval: 5,
        offset_commit_threshold: 100
      )

      @outgoingKafkaConsumer.subscribe "outgoing-messages", start_from_beginning: false

      @outgoingKafkaConsumer.each_message do |message|
        if @stopRunning
          break
        end
        @ircConnection.send message.value
      end
    end
  end

  def createCommandProcessingThread
    return Thread.new do
      commander = TwitchMessageCommander.new

      @commandKafkaConsumer = @kafka.consumer(
        group_id: "command-chat-consumer",
        offset_commit_interval: 5,
        offset_commit_threshold: 100
      )

      @commandKafkaConsumer.subscribe "incoming-messages", start_from_beginning: false

      @commandKafkaConsumer.each_message do |message|
        if @stopRunning
          break
        end
        commander.call @kafkaProducer, message.value
      end
    end
  end

  def setupIrcConnection
    puts "#{@ircUri}, #{@ircPort}, #{@ircNickname}, #{@ircPassword}"
    @ircConnection = IrcConnection.new @ircUri, @ircPort, @ircNickname, @ircPassword
    @ircConnection.connect
    @ircConnection.send "PASS oauth:#{@ircPassword}\r\nNICK #{@ircNickname}\r\n"
    @ircConnection.send "JOIN #{@targetChannel}"
  end

  def readFromTwitch
    puts "Setting up kafka producer"
    @kafkaProducer = @kafka.producer

    messagesReceived = 0
    until @ircConnection.socket.eof? do
      if @stopRunning
        break
      end

      message = @ircConnection.socket.gets
      messagesReceived += 1
      puts "Received from twitch: #{message}"

      unless message.nil? || message == "" 
        @kafkaProducer.produce(message, topic: "incoming-messages")
        @kafkaProducer.deliver_messages
      end
    end
  end

  def run
    trap("INT") { quit }
    trap("QUIT") { quit }

    setupIrcConnection

    @threads = [
      createWriteThread,
      createCommandProcessingThread
    ]

    @threads.each {|t| t.abort_on_exception = true}

    readFromTwitch
  end

  def quit
    puts "Shutting down"
    @stopRunning = true
    @ircConnection.send "QUIT"
    puts "Killing kafka producer"
    @kafkaProducer.shutdown unless @kafkaProducer.nil?
    puts "Killing outgoing kafka consumer"
    @outgoingKafkaConsumer.stop unless @outgoingKafkaConsumer.nil?
    puts "Killing command kafka consumer"
    @commandKafkaConsumer.stop unless @commandKafkaConsumer.nil?
    @threads.each(&:join)
  end
end
