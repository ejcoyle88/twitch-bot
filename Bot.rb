#!/usr/bin/env ruby

require 'kafka'

require './IrcConnection'

class Bot
  def initialize settings
    @targetChannel = settings[:channel]
    @ircUri = settings[:ircUri]
    @ircPort = settings[:ircPort]
    @ircNickname = settings[:ircNickname]
    @ircPassword = settings[:ircPassword]
    @stopRunning = false

    @kafka = Kafka.new(
      seed_brokers: settings[:kafka_seed_brokers],
      client_id: settings[:kafka_client_id]
    )
  end

  def createWriteThread
    return Thread.new do
      @kafkaConsumer = @kafka.consumer(
        group_id: "outgoing-chat-consumer",
        offset_commit_interval: 5,
        offset_commit_threshold: 100
      )

      @kafkaConsumer.subscribe "outgoing-messages", start_from_beginning: false

      @kafkaConsumer.each_message do |outgoing|
        @ircConnection.send outgoing.value
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
        @kafkaProducer.deliver_messages if (messagesReceived % 10) == 0
      end
    end
  end


  def run
    trap("INT") { quit }
    trap("QUIT") { quit }

    setupIrcConnection

    @threads = [
      createWriteThread
    ]

    @threads.each {|t| t.abort_on_exception = true}

    readFromTwitch
  end

  def quit
    puts "Shutting down"
    @stopRunning = true
    @ircConnection.send "QUIT"
    unless @kafkaProducer.nil?
      puts "Killing kafka producer"
      @kafkaProducer.shutdown
    end
    unless @kafkaConsumer.nil?
      puts "Killing kafka consumer"
      @kafkaConsumer.stop
    end
    @threads.each(&:join)
  end
end
