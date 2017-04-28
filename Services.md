#Services
This could all be split out into the below services

IrcConnectionService
  Writes all IRC messages to the raw-incoming-messages kafka channel.
  Writes all messages in the outgoing-messages kafka channel to IRC.

IrcMessageFormattingService
  Reads all messages from raw-incoming-messages and processes them into
  something more useful, writing them back to the incoming-messages kafka
  channel.

XCommandService
  Specific command services, watching the incoming-messages channel for triggers,
  and writing their output to the outgoing-messages channel in kafka.

IrcMessageLogger
  Takes ALL IRC messages and logs them into an ElasticSearch database, for
  looking up later.
