import { Batch, KafkaMessage } from "@confluentinc/kafka-javascript/types/kafkajs";
import { ConsumerOffsetMsg, ConsumerOffsetMsgKind, GroupMetadataMember, GroupMetadataMsgKey, GroupMetadataMsgValue, IConsumerOffsetMsgDecoder, IConsumerOffsetMsgKeyDecoder, IConsumerOffsetMsgValueDecoder, OffsetCommitMsgKey, OffsetCommitMsgValue, UnknownMsgKey, UnknownMsgValue } from "./data-structures";

// Helper to read Kafka length-prefixed strings
function readKafkaString(buffer: Buffer, startOffset: number): { value: string | null; nextOffset: number } {
  if (startOffset >= buffer.length) return { value: null, nextOffset: startOffset };
  const length = buffer.readInt16BE(startOffset);
  if (length === -1) return { value: null, nextOffset: startOffset + 2 };
  const value = buffer.toString('utf8', startOffset + 2, startOffset + 2 + length);
  return { value, nextOffset: startOffset + 2 + length };
}

export class OffsetCommitKeyAndValueDecoder implements IConsumerOffsetMsgKeyDecoder, IConsumerOffsetMsgValueDecoder {
  decodeKey(key: Buffer): OffsetCommitMsgKey {
    const version = key.readInt16BE(0);
    let currentOffset = 2;

    const groupData = readKafkaString(key, currentOffset);
    currentOffset = groupData.nextOffset;

    const topicData = readKafkaString(key, currentOffset);
    currentOffset = topicData.nextOffset;

    const partition = key.readInt32BE(currentOffset);

    return {
      discriminator: 'OFFSET_COMMIT',
      version,
      groupId: groupData.value || '',
      topic: topicData.value || '',
      partition,
    };
  }

  decodeValue(value: Buffer): OffsetCommitMsgValue {
    const version = value.readInt16BE(0);
    let currentOffset = 2;
    const parsedValue: any = { discriminator: 'OFFSET_COMMIT', version };

    if (version >= 0 && version <= 3) {
      parsedValue.offset = value.readBigInt64BE(currentOffset);
      currentOffset += 8;

      if (version === 3) {
        parsedValue.leaderEpoch = value.readInt32BE(currentOffset);
        currentOffset += 4;
      }

      const metadataData = readKafkaString(value, currentOffset);
      parsedValue.metadata = metadataData.value;
      currentOffset = metadataData.nextOffset;

      parsedValue.commitTimestamp = value.readBigInt64BE(currentOffset);
      currentOffset += 8;

      if (version === 1 && currentOffset + 8 <= value.length) {
        parsedValue.expireTimestamp = value.readBigInt64BE(currentOffset);
      }
    }
    return parsedValue as OffsetCommitMsgValue;
  }
}

export class GroupMetadataKeyAndValueDecoder implements IConsumerOffsetMsgKeyDecoder, IConsumerOffsetMsgValueDecoder {
  
  decodeKey(key: Buffer): GroupMetadataMsgKey {
    const version = key.readInt16BE(0);
    const groupData = readKafkaString(key, 2);

    return {
      discriminator: 'GROUP_METADATA',
      version,
      groupId: groupData.value || '',
    };
  }

  decodeValue(value: Buffer): GroupMetadataMsgValue {
    // A null value or empty buffer is a tombstone message (group deletion)
    if (!value || value.length === 0) {
      return { discriminator: 'GROUP_METADATA', version: -1, members: [] };
    }

    const version = value.readInt16BE(0);
    let currentOffset = 2;

    const protocolTypeData = readKafkaString(value, currentOffset);
    currentOffset = protocolTypeData.nextOffset;

    const generation = value.readInt32BE(currentOffset);
    currentOffset += 4;

    const protocolData = readKafkaString(value, currentOffset);
    currentOffset = protocolData.nextOffset;

    const leaderData = readKafkaString(value, currentOffset);
    currentOffset = leaderData.nextOffset;

    let currentStateTimestamp: bigint | undefined = undefined;
    if (version >= 2) {
      currentStateTimestamp = value.readBigInt64BE(currentOffset);
      currentOffset += 8;
    }

    const membersCount = value.readInt32BE(currentOffset);
    currentOffset += 4;
    const members: GroupMetadataMember[] = [];

    for (let i = 0; i < membersCount; i++) {
      const memberIdData = readKafkaString(value, currentOffset);
      currentOffset = memberIdData.nextOffset;

      let groupInstanceId: string | null = null;
      if (version >= 3) {
        const groupInstanceIdData = readKafkaString(value, currentOffset);
        groupInstanceId = groupInstanceIdData.value;
        currentOffset = groupInstanceIdData.nextOffset;
      }

      const clientIdData = readKafkaString(value, currentOffset);
      currentOffset = clientIdData.nextOffset;

      const clientHostData = readKafkaString(value, currentOffset);
      currentOffset = clientHostData.nextOffset;

      const rebalanceTimeout = value.readInt32BE(currentOffset);
      currentOffset += 4;

      const sessionTimeout = value.readInt32BE(currentOffset);
      currentOffset += 4;

      // SKIP SUBSCRIPTION: Read the 32-bit length, and jump the offset forward
      const subscriptionLength = value.readInt32BE(currentOffset);
      currentOffset += 4;
      if (subscriptionLength > 0) {
        currentOffset += subscriptionLength;
      }

      // SKIP ASSIGNMENT: Read the 32-bit length, and jump the offset forward
      const assignmentLength = value.readInt32BE(currentOffset);
      currentOffset += 4;
      if (assignmentLength > 0) {
        currentOffset += assignmentLength;
      }

      members.push({
        memberId: memberIdData.value,
        groupInstanceId,
        clientId: clientIdData.value,
        clientHost: clientHostData.value,
        rebalanceTimeout,
        sessionTimeout,
      });
    }

    return {
      discriminator: 'GROUP_METADATA',
      version,
      protocolType: protocolTypeData.value,
      generation,
      protocol: protocolData.value,
      leader: leaderData.value,
      currentStateTimestamp,
      members,
    };
  }
}

export class UnknownKeyAndValueDecoder implements IConsumerOffsetMsgKeyDecoder, IConsumerOffsetMsgValueDecoder {
  decodeKey(key: Buffer): UnknownMsgKey {
    return {
      discriminator: 'UNKNOWN',
      version: key.length >= 2 ? key.readInt16BE(0) : -1,
    };
  }

  decodeValue(value: Buffer): UnknownMsgValue {
    return {
      discriminator: 'UNKNOWN',
      version: value.length >= 2 ? value.readInt16BE(0) : -1,
    };
  }
}
export class ConsumerOffsetMsgDecodersFactory {
  private static instance: ConsumerOffsetMsgDecodersFactory;

  private constructor() {}

  public static getInstance$(): ConsumerOffsetMsgDecodersFactory {
    if (!ConsumerOffsetMsgDecodersFactory.instance) {
      ConsumerOffsetMsgDecodersFactory.instance = new ConsumerOffsetMsgDecodersFactory();
    }
    return ConsumerOffsetMsgDecodersFactory.instance;
  }

  public getMsgDecoder(): IConsumerOffsetMsgDecoder {
    return new ConsumerOffsetMsgDecoder();
  }

  public getMsgKeyDecoder(msgKind: ConsumerOffsetMsgKind): IConsumerOffsetMsgKeyDecoder {
    switch (msgKind) {
      case ConsumerOffsetMsgKind.OFFSET_COMMIT:
        return new OffsetCommitKeyAndValueDecoder();
      case ConsumerOffsetMsgKind.GROUP_METADATA:
        return new GroupMetadataKeyAndValueDecoder();
      default:
        return new UnknownKeyAndValueDecoder();
    }
  }

  public getMsgValueDecoder(msgKind: ConsumerOffsetMsgKind): IConsumerOffsetMsgValueDecoder {
    switch (msgKind) {
      case ConsumerOffsetMsgKind.OFFSET_COMMIT:
        return new OffsetCommitKeyAndValueDecoder();
      case ConsumerOffsetMsgKind.GROUP_METADATA:
        return new GroupMetadataKeyAndValueDecoder();
      default:
        return new UnknownKeyAndValueDecoder();
    }
  }
}

export class ConsumerOffsetMsgDecoder implements IConsumerOffsetMsgDecoder {
  private readonly decodersFactory = ConsumerOffsetMsgDecodersFactory.getInstance$();

  public decodeMsg( batch: Batch, msg: KafkaMessage): ConsumerOffsetMsg {
    const baseInfo = this.decodeBaseInformation( batch, msg);
    const msgKind = this.inferMsgKind(msg);

    const keyBuffer = msg.key || Buffer.from([]);
    const valueBuffer = msg.value

    const keyDecoder = this.decodersFactory.getMsgKeyDecoder(msgKind);
    const valueDecoder = this.decodersFactory.getMsgValueDecoder(msgKind);

    const decodedKey = keyDecoder.decodeKey(keyBuffer);
    // If value is missing (e.g., tombstones)
    const decodedValue = (valueBuffer ? valueDecoder.decodeValue(valueBuffer) : null);

    return {
      ...baseInfo,
      kind: msgKind,
      key: decodedKey,
      value: decodedValue,
    };
  }

  private decodeBaseInformation( batch: Batch, msg: KafkaMessage): any {
    return {
      consumerOffsetTopicPartition: batch.partition,
      msgTimestampEpoch: parseInt(msg.timestamp, 10),
      msgOffset: parseInt(msg.offset, 10),
      msgSize: msg.size,
    };
  }

  private inferMsgKind(msg: KafkaMessage): ConsumerOffsetMsgKind {
    if (!msg.key || msg.key.length < 2) {
      return ConsumerOffsetMsgKind.UNKNOWN;
    }

    const version = msg.key.readInt16BE(0);
    
    if (version === 0 || version === 1) {
      return ConsumerOffsetMsgKind.OFFSET_COMMIT;
    } else if (version === 2) {
      return ConsumerOffsetMsgKind.GROUP_METADATA;
    }

    return ConsumerOffsetMsgKind.UNKNOWN;
  }
}
