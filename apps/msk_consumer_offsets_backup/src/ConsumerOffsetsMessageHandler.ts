import { Logger } from "pino";

import { Batch, EachBatchPayload, KafkaMessage, TopicPartitionOffsetAndMetadata } from "@confluentinc/kafka-javascript/types/kafkajs";
import { S3MessageSaver } from "./aws-s3-indexer/S3MessageSaver";
import { IMessageSaver, MessageEntry } from "./aws-s3-indexer/types";
import { ConsumerOffsetMsg, ConsumerOffsetMsgKind, IConsumerOffsetMsgDecoder, OffsetCommitMsgKey } from "./msg-decoder/data-structures";
import { ConsumerOffsetMsgDecodersFactory } from "./msg-decoder/decoders";
import { ConsumersOffsetsDumperConfig } from "./Config";

type OffsetsMap = { [ p: number ]: string };

function currentEpoch() {
  return Math.round( (new Date()).getTime() / 1000)
}

export class ConsumerOffsetMessageHandler {

  private logger: Logger;

  private msgDecoder: IConsumerOffsetMsgDecoder;
  private msgSaver: IMessageSaver;

  private internalTopicName: string;
  private destinationBaseUrl: string;
  private savingBatchSize: number;
  private savingBatchSeconds: number;

  private lastOffsetsToCommit: OffsetsMap = {};
  private jsonMessages: MessageEntry[] = [];
  private lastSaveEpoch: number = 0;


  constructor( logger: Logger, internalTopicName: string, config: ConsumersOffsetsDumperConfig) {
    this.logger = logger;

    const msgDecoderFactory = ConsumerOffsetMsgDecodersFactory.getInstance$();
    this.internalTopicName = internalTopicName;
    this.destinationBaseUrl = this.buildS3BaseUrl( config.s3DestinationBucketName, config.s3DestinationPathPrefix);
    this.savingBatchSize = config.savingBatchSize;
    this.savingBatchSeconds = config.savingBatchSeconds;

    this.msgDecoder = msgDecoderFactory.getMsgDecoder();
    this.msgSaver = new S3MessageSaver( config.awsRegion );

    this.initMessages();
  }

  private initMessages() {
    this.lastOffsetsToCommit = {};
    this.jsonMessages = [];
    this.lastSaveEpoch = currentEpoch();
  }

  public async handleBatch( params: EachBatchPayload): Promise<TopicPartitionOffsetAndMetadata[]> {
    const batch = params.batch;
    const heartbeat = params.heartbeat;
    const isRunning = params.isRunning;
    const isStale = params.isStale;

    this.logger.debug(` - Start handling a batch of length ${batch.messages.length} ` 
          + `at partition ${batch.partition} offset ${batch.firstOffset()}`);
    
    for (const message of batch.messages) {
      if (!isRunning() || isStale()) break;
      this.handleOneMessage( batch, message );
      await heartbeat();
    }
    
    let offsetsToBeCommitted: TopicPartitionOffsetAndMetadata[];

    if ( this.haveToFlush() ) {
      offsetsToBeCommitted = await this.flushMessagesToStorage();
    }
    else {
      offsetsToBeCommitted = []
    }
    
    return offsetsToBeCommitted;
  }

  private handleOneMessage( batch: Batch, message: KafkaMessage ) {
    const decodedMessage = this.msgDecoder.decodeMsg( batch, message );
    const messageJsonString = this.decodedMessageToJson( decodedMessage );
    
    const shouldCommit = ! this.isInternalTopicCommitMessage( decodedMessage );
    if (shouldCommit) {
        this.lastOffsetsToCommit[ batch.partition ] = message.offset;
    } else {
        this.logger.debug(`   Skipping commit update for message: ${messageJsonString}`);
    }
    this.jsonMessages.push( { json: messageJsonString, ts: message.timestamp } );
  }

  private haveToFlush() {
    const enoughMessages = this.jsonMessages.length >= this.savingBatchSize;
    const timeLimitExpired = this.lastSaveEpoch + this.savingBatchSeconds < currentEpoch()
    return enoughMessages || timeLimitExpired;
  }

  private async flushMessagesToStorage(): Promise<TopicPartitionOffsetAndMetadata[]> {
    this.logger.info(` - Saving ${this.jsonMessages.length} messages to S3`);
    const savedFiles = await this.msgSaver.saveMessages( this.destinationBaseUrl, this.jsonMessages );
    this.logger.info(`   Saved Files: ${JSON.stringify(savedFiles)}`);
    this.logger.info(`   Commit offsets: ${JSON.stringify( this.lastOffsetsToCommit)}`);
    const offsetsToBeCommitted = this.offsetsMapToOffsetsArray( this.lastOffsetsToCommit );
    this.initMessages();
    return offsetsToBeCommitted;
  }

  private decodedMessageToJson( decodedMessage: ConsumerOffsetMsg ) {
    return JSON.stringify(
      decodedMessage, 
      (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
  }

  private isInternalTopicCommitMessage( decodedMessage: ConsumerOffsetMsg ) {
    let isInternalOffsetCommit = ( decodedMessage.kind === ConsumerOffsetMsgKind.OFFSET_COMMIT );
    if( isInternalOffsetCommit ) {
      if( 'topic' in decodedMessage.key ) {
        const decodedMessageKey: OffsetCommitMsgKey = decodedMessage.key as OffsetCommitMsgKey;
        isInternalOffsetCommit = ( decodedMessageKey.topic == this.internalTopicName )
      }
      else {
        isInternalOffsetCommit = false;
      }
    }
    return isInternalOffsetCommit;
  }

  private offsetsMapToOffsetsArray( offsetsMap: OffsetsMap ): TopicPartitionOffsetAndMetadata[] {
    return Object.entries( offsetsMap ).map( ( partitionOffsetStringsArray ) => {
      const partition = parseInt( partitionOffsetStringsArray[0] );
      const nextOffset = (BigInt( partitionOffsetStringsArray[1] ) + 1n).toString();
      const offsetCommitElement = { 
        topic: this.internalTopicName,
        partition,
        offset: nextOffset
      }
      return offsetCommitElement;
    });
  }

  private buildS3BaseUrl( bucket: string, prefix: string): string {
    if( !bucket || bucket.includes("/")) {
      const msg = "Bucket name must be not empty and can't contains '/'"
      this.logger.error( msg );
      throw new Error( msg );
    }
    if( !prefix || prefix.startsWith("/")) {
      const msg = "S3 path prefix must be not empty and can't starts with '/'"
      this.logger.error( msg );
      throw new Error( msg );
    }

    let baseS3Url = "s3://" + bucket + "/" + prefix;
    if( ! baseS3Url.endsWith("/") ) {
      baseS3Url += "/";
    }
    return baseS3Url;
  }

}
