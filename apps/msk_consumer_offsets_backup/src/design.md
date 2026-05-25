# ``dump-kafka-consumer_offsets-topic`` application design

This document describes the overall application design, including configuration,
message handling, and the application entrypoint. Persisted storage is supported
through S3 buckets.

## Class diagram
```mermaid
classDiagram
    direction TB

    class ConsumersOffsetsDumperConfig {
        <<type>>
        +readonly kafkaBootstrapServers string
        +readonly s3DestinationBaseUrl string
        +readonly awsRegion string
        +readonly consumerGroupName string
        +readonly s3SavingBatchSize number // min:1 ; max: 1000 * 1000
        +readonly s3SavingBatchSeconds number // min:60 ; max:3600
    }

    class ConsumerOffsetMessageHandler {

        +handleBatch( EachBatchPayload params ) Promise<TopicPartitionOffsetAndMetadata[]>

        -handleOneMessage( Batch batch, KafkaMessage message )
        -haveToFlush()
        -flushMessagesToStorage()
    }
    
```

## Class responsibilities
 - __MessageEntry__ is a data structure that contains a JSON on one line and a 
   original message creation timestamp (ts); the timestamp is an epoch milliseconds number.
 - __IMessageSaver__ interface of classes used to save messages on some storage. The 
   only method _saveMessages_ get an URL and a list of messages. Can throw an error 
   if the URL is not supported. Return the list of created resources.
 - __S3MessageSaver__ support s3 like URLs and save JSON messages of one line into 
   S3 objects with key in the form ``<URL-path>/kind=<kindField>/year=<timestamp-YYYY>/month=<timestamp-MM>/day=<timestamp-DD>/<UUID>.ndjson`` 
   into bucket ``<URL-domain>``. Where _kindField_ is the content of field named kind 
   in the JSON message; 'NONE' if the field is absent or empty.
   This class configure the ``AWS_REGION`` to use from environment variable with a default 
   of ``eu-south-1``.

## ConsumerOffsetMessageHandler::handleBatch sequence diagram
```mermaid
sequenceDiagram
    participant Caller as Kafka Consumer (Caller)
    participant Handler as ConsumerOffsetMessageHandler
    participant Decoder as IConsumerOffsetMsgDecoder
    participant Saver as IMessageSaver

    Caller->>+Handler: handleBatch(params)
    
    loop For each message in batch.messages
        Handler->>+Handler: handleOneMessage(batch, message)
        Handler->>+Decoder: decodeMsg( Batch batch, KafkaMessage msg )
        Decoder->>-Handler: return decoded message
        Note over Handler: if committed offset topic is not __consumer_offsets then update list of readed offsets
        Handler->>-Handler: handleOneMessage END
    end

    alt haveToFlush() is true
        Handler->>+Saver: await flushMessagesToStorage()
        Saver->>-Handler: return list of created files
        Note over Handler: offsetsToBeCommitted := last readed offset by partition
    else haveToFlush() is false
        Note over Handler: offsetsToBeCommitted := []
    end

    Handler-->>-Caller: return offsetsToBeCommitted
```

## index runConsumer
This is the entrypoint of the containerized application it simply

 - Parse environment variables using [zod](https://www.npmjs.com/package/zod)
 - Initialize [pino](https://github.com/pinojs/pino) logger.
 - Connect to kafka to consume ``__consumer_offsets`` topic using 
   [confluent kafka client library](https://docs.confluent.io/kafka-clients/javascript/current/overview.html).
 - Configure shutdown hook.
 - Start consuming batch manually handling offset commit; use an instance of 
   ``ConsumerOffsetMessageHandler``.
