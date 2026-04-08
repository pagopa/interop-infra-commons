import { EachMessagePayload, KafkaMessage, Batch } from "@confluentinc/kafka-javascript/types/kafkajs";

// --- ENUMERATIONS AND UNIONS ---
export enum ConsumerOffsetMsgKind {
  OFFSET_COMMIT = 'OFFSET_COMMIT',
  GROUP_METADATA = 'GROUP_METADATA',
  UNKNOWN = 'UNKNOWN',
}

export type ConsumerOffsetMsgKey = OffsetCommitMsgKey | GroupMetadataMsgKey | UnknownMsgKey;
export type ConsumerOffsetMsgValue = OffsetCommitMsgValue | GroupMetadataMsgValue | UnknownMsgValue;

// --- KEY SPECIALIZATIONS ---
export type OffsetCommitMsgKey = {
  discriminator: 'OFFSET_COMMIT';
  readonly version: number;
  readonly groupId: string;
  readonly topic: string;
  readonly partition: number;
};

export type GroupMetadataMsgKey = {
  discriminator: 'GROUP_METADATA';
  readonly version: number;
  readonly groupId: string;
  readonly topic?: string;
  readonly partition?: number;
};

export type UnknownMsgKey = {
  discriminator: 'UNKNOWN';
  readonly version: number;
};

// --- VALUE SPECIALIZATIONS ---
export type OffsetCommitMsgValue = {
  discriminator: 'OFFSET_COMMIT';
  readonly version: number;
  readonly offset?: bigint;
  readonly leaderEpoch?: number;
  readonly metadata?: string | null;
  readonly commitTimestamp?: bigint;
  readonly expireTimestamp?: bigint;
};

export type GroupMetadataMsgValue = {
  discriminator: 'GROUP_METADATA';
  readonly version: number;
  readonly protocolType?: string | null;
  readonly generation?: number;
  readonly protocol?: string | null;
  readonly leader?: string | null;
  readonly currentStateTimestamp?: bigint; // Added in Kafka GroupMetadata v2
  readonly members?: GroupMetadataMember[];
};

export type GroupMetadataMember = {
  readonly memberId: string | null;
  readonly groupInstanceId?: string | null; // Added in Kafka GroupMetadata v3
  readonly clientId: string | null;
  readonly clientHost: string | null;
  readonly rebalanceTimeout: number;
  readonly sessionTimeout: number;
};


export type UnknownMsgValue = {
  discriminator: 'UNKNOWN';
  readonly version: number;
};

// --- FINAL WRAPPER ---
export type ConsumerOffsetMsg = {
  readonly consumerOffsetTopicPartition: number;
  readonly msgTimestampEpoch: number;
  readonly msgOffset: number;
  readonly msgSize: number;
  readonly kind: ConsumerOffsetMsgKind;
  readonly key: ConsumerOffsetMsgKey;
  readonly value: ConsumerOffsetMsgValue;
};

// --- INTERFACES ---
export interface IConsumerOffsetMsgDecoder {
  decodeMsg(batch: Batch, msg: KafkaMessage): ConsumerOffsetMsg;
}

export interface IConsumerOffsetMsgKeyDecoder {
  decodeKey(key: Buffer): ConsumerOffsetMsgKey;
}

export interface IConsumerOffsetMsgValueDecoder {
  decodeValue(value: Buffer): ConsumerOffsetMsgValue;
}
