import { Logger } from "pino";

import { EachBatchPayload, TopicPartitionOffsetAndMetadata } from "@confluentinc/kafka-javascript/types/kafkajs";
import { S3MessageSaver } from "./aws-s3-indexer/S3MessageSaver";
import { IMessageSaver, MessageEntry } from "./aws-s3-indexer/types";
import { ConsumerOffsetMsg, IConsumerOffsetMsgDecoder, OffsetCommitMsgKey } from "./msg-decoder/data-structures";
import { ConsumerOffsetMsgDecodersFactory } from "./msg-decoder/decoders";

type OffsetsMap = { [ p: number ]: string };

export class ConsumerOffsetMessageHandler {

  private logger: Logger;

  private msgDecoder: IConsumerOffsetMsgDecoder;
  private msgSaver: IMessageSaver;

  private internalTopicName: string;
  private s3destinationBaseUrl: string;

  constructor( logger: Logger, region: string, internalTopicName: string, s3destinationBaseUrl: string) {
    this.logger = logger;

    const msgDecoderFactory = ConsumerOffsetMsgDecodersFactory.getInstance$();
    this.msgDecoder = msgDecoderFactory.getMsgDecoder();
    this.msgSaver = new S3MessageSaver( region );

    this.internalTopicName = internalTopicName;
    this.s3destinationBaseUrl = s3destinationBaseUrl;
  }

  public async handleBatch( params: EachBatchPayload): Promise<TopicPartitionOffsetAndMetadata[]> {
    const batch = params.batch;
    const heartbeat = params.heartbeat;
    const isRunning = params.isRunning;
    const isStale = params.isStale;

    this.logger.info(` - Start handling a batch of length ${batch.messages.length} ` 
          + `at partition ${batch.partition} offset ${batch.firstOffset()}`);
    
    const lastOffsetsToCommit: OffsetsMap = {};
    const jsonMessages: MessageEntry[] = []

    for (const message of batch.messages) {
      if (!isRunning() || isStale()) break;

      const decodedMessage = this.msgDecoder.decodeMsg( batch, message );
      const messageJsonString = this.decodedMessageToJson( decodedMessage );
      
      const shouldCommit = ! this.isInternalTopicCommitMessage( decodedMessage );
      if (shouldCommit) {
          lastOffsetsToCommit[ batch.partition ] = message.offset;
      } else {
          this.logger.debug(`   Skipping commit update for message: ${messageJsonString}`);
      }
      jsonMessages.push( { json: messageJsonString, ts: message.timestamp } );

      await heartbeat();
    }
  
    await this.msgSaver.saveMessages( this.s3destinationBaseUrl, jsonMessages );

    this.logger.debug(`   Commit offsets: ${JSON.stringify(lastOffsetsToCommit)}`);
    return this.offsetsMapToOffsetsArray( lastOffsetsToCommit );
  }

  private decodedMessageToJson( decodedMessage: ConsumerOffsetMsg ) {
    return JSON.stringify(
      decodedMessage, 
      (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
  }

  private isInternalTopicCommitMessage( decodedMessage: ConsumerOffsetMsg ) {
    let isInternalOffsetCommit = ( decodedMessage.kind === "OFFSET_COMMIT" );
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

}
