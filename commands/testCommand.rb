#!/usr/bin/env ruby

require 'kafka'
require 'yaml'

class TestCommand
	def initialize
		@settings = YAML::load_file("../config/application.yml")
	end

	def run
    puts "Setup"
    keepRunning = true
    trap("INT") { keepRunning = false }
    trap("QUIT") { keepRunning = false }

		kafka = Kafka.new(
			seed_brokers: @settings[:kafka_seed_brokers],
			client_id: @settings["#{:kafka_client_id}_testCommand" ]
		)

		consumer = kafka.consumer(
			group_id: "testCommand-consumer",
			offset_commit_interval: 5,
			offset_commit_threshold: 100
		)

		producer = kafka.producer

		consumer.subscribe "incoming-messages", start_from_beginning: false

		consumedMessages = 0
    while keepRunning do
      puts "Running"
      consumer.each_message do |kfMessage|
        message = kfMessage.value
        puts message
        message.strip!()
        baseTriple = message.split(' ', 3)
        messageType = baseTriple[1]
        if messageType == "PRIVMSG"
          nick = baseTriple[0].split('!', 2)[0][1..-1]
          meta = baseTriple[2].split(' :', 2)
          msg = meta[1]
          if nick == "vaeix" && msg == "!test"
            puts "Found a test command!"
            producer.produce ":vaeixbot!vaeixbot@vaeixbot.tmi.twitch.tv PRIVMSG #wunair :Successful test!", topic: "outgoing-messages"
            producer.deliver_messages if (consumedMessages % 10) == 0
          end
        end
        consumedMessages += 1
      end
    end

    producer.shutdown
    consumer.stop
	end
end

command = TestCommand.new
command.run
