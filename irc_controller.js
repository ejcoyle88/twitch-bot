import { Socket } from 'net';

class IrcConnection {
  constructor(uri, port) {
    this.uri = uri;
    this.port = port;
  }
  async connect() {
    this.socket = new Socket();

    this.socket.setEncoding('ascii');
    this.socket.setNoDelay();
    this.socket.connect(this.port, this.uri);

    let socket = this.socket;
    return new Promise((rs, rj) => socket.on('connect', () => rs(socket)));
  }
  read(callback) {
    this.socket.on('data', function(data) {
      let lines = data.split('\n');
      let linesLength = lines.length;
      for(let i = 0; i < linesLength; i++) {
        let currentLine = lines[i];
        if(currentLine != '') {
          callback(currentLine);
        }
      }
    });
  }
  write(message) {
    this.socket.write(`${message}\n`, 'ascii');
  }
}

class IrcMessage {
  constructor(message) {

  }
}

class KafkaMessageWriter {
  constructor(kafkaClient) {
    this.kafkaClient = kafkaClient;
    this.producer = new KafkaProducer(kafkaClient);
  }
  write(topic, message) {
    this.producer.send([{ topic: topic, messages: [message] }]);
  }
}

class KafkaMessageReader {
  constructor(kafkaClient) {
    this.kafkaClient = kafkaClient;
  }
  read(topic, callback) {
    if(this.consumer == null) {
      this.consumer = new KafkaConsumer(kafkaClient, [{ topic: topic }]);
    }

    this.consumer.on('message', (kafkaMessage) => callback(kafkaMessage));
  }
}

class BotMessageReader {
  constructor(kafkaWriter, ircConnection) {
    this.kafkaWriter = kafkaWriter;
    this.irc = ircConnection;
  }
  async startReading() {
    this.irc.read((message) => this.kafkaWriter.write('incomingMessages', message));
  }
}

class BotMessageWriter {
  constructor(kafkaReader, ircConnection) {
    this.kafkaReader = kafkaReader;
    this.irc = ircConnection;
  }
  async startWriting() {
    this.kafkaReader.read('outgoingMessages', (message) => this.irc.write(message));
  }
}

function getEnv(key, default) {
  return process.env[key] ? process.env[key] : default;
}

function createConstants() {
  let args = arguments.slice();
  let result = {};

  let prefix = args[0];
  let constants = args.slice(1);
  let constantsLength = constants.length;

  for(let i = 0; i < constantsLength; i++) {
    let constant = constants[i];
    result[constant] = `${prefix}_${constant}`;
  }

  return result;
}

class Settings {
  constructor() {
    const envKeys = createConstants(
      'TWITCH_BOT',
      'IRC_URI',
      'IRC_PORT',
      'ZOOKEEPER_URI',
      'ZOOKEEPER_CLIENT_ID'
    );

    this.irc_uri = getEnv(envKeys.IRC_URI, 'irc.chat.twitch.tv');
    this.irc_port = parseInt(getEnv(envKeys.IRC_PORT, '6667'), 10);
    this.zookeper_uri = getEnv(envKeys.ZOOKEEPER_URI, 'localhost:2181/');
    this.zookeeper_client_id = getEnv(envKeys.ZOOKEEPER_CLIENT_ID, 'twitch-bot-irc-controller');
  }
}

class Bot {
  constructor(settings) {
    this.settings = settings;

    this.irc = new IrcConnection(
      settings.irc_uri,
      settings.irc_port
    );

    this.kafka = new KafkaClient(
      settings.zookeeper_uri,
      settings.zookeeper_client_id
    );
  }
  async run() {
    let socket = await this.irc.connect();

    this.reader.startReading();
    this.reader.startWriting();
  }
}
