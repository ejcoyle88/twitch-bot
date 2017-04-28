import { Socket } from 'net';
import {
  Client as KafkaClient,
  Producer as KafkaProducer,
  Consumer as KafkaConsumer,
} from 'kafka-node';

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

    const socket = this.socket;
    return new Promise(rs => socket.on('connect', () => rs(socket)));
  }
  read(callback) {
    this.socket.on('data', (data) => {
      const lines = data.split('\n');
      const linesLength = lines.length;
      for (let i = 0; i < linesLength; i += 1) {
        const currentLine = lines[i];
        if (currentLine !== '') {
          callback(currentLine);
        }
      }
    });
  }
  write(message) {
    this.socket.write(`${message}\n`, 'ascii');
  }
  on(evnt, cb) {
    this.socket.on(evnt, cb);
  }
}

class KafkaMessageWriter {
  constructor(kafkaClient) {
    this.kafkaClient = kafkaClient;
    this.producer = new KafkaProducer(kafkaClient);
  }
  write(topic, message) {
    this.producer.send([{ topic, messages: [message] }]);
  }
}

class KafkaMessageReader {
  constructor(kafkaClient) {
    this.kafkaClient = kafkaClient;
  }
  read(topic, callback) {
    if (this.consumer == null) {
      this.consumer = new KafkaConsumer(this.kafkaClient, [{ topic }]);
    }

    this.consumer.on('message', kafkaMessage => callback(kafkaMessage));
  }
}

class BotMessageReader {
  constructor(kafkaWriter, ircConnection) {
    this.kafkaWriter = kafkaWriter;
    this.irc = ircConnection;
  }
  async startReading() {
    this.irc.read(message => {
      console.log(message);
      this.kafkaWriter.write('incomingMessages', message);
    });
  }
  readOnce(message) {
    this.kafkaWriter.write('incomingMessages', message);
  }
}

class BotMessageWriter {
  constructor(kafkaReader, ircConnection) {
    this.kafkaReader = kafkaReader;
    this.irc = ircConnection;
  }
  async startWriting() {
    this.kafkaReader.read('outgoingMessages', message => this.irc.write(message));
  }
}

function getEnv(key, otherwise) {
  return process.env[key] ? process.env[key] : otherwise;
}

function createConstants(prefix, ...constants) {
  const result = {};
  const constantsLength = constants.length;

  for (let i = 0; i < constantsLength; i += 1) {
    const constant = constants[i];
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
      'ZOOKEEPER_CLIENT_ID',
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
      settings.irc_port,
    );

    this.kafka = new KafkaClient(
      settings.zookeeper_uri,
      settings.zookeeper_client_id,
    );
  }
  async run(onClose) {
    const p = new Promise(onClose);
    const socket = await this.irc.connect();
    this.irc.on('close', (hadError) => {
      if (hadError) { p.reject(); } else { p.resolve(); }
    });

    const kafkaWriter = new KafkaMessageWriter(this.kafka);
    const reader = new BotMessageReader(kafkaWriter, socket);

    const kafkaReader = new KafkaMessageReader(this.kafka);
    const writer = new BotMessageWriter(kafkaReader, socket);

    reader.startReading();
    writer.startWriting();

    reader.readOnce('CONNECTED');
  }
}

const settings = new Settings();
const bot = new Bot(settings);

let running = true;
bot.run(() => { running = false; });

console.log('Now listening for IRC messages');
while (running) {}
