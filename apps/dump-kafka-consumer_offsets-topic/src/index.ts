import { KafkaJS } from "@confluentinc/kafka-javascript";

import { MskDiscovery } from "./aws-msk-utils/MskDiscovery";
import { oauthBearerTokenProvider } from "./aws-msk-utils/AuthProvider";
import { EachMessagePayload } from "@confluentinc/kafka-javascript/types/kafkajs";
import { ConsumerOffsetMsgDecodersFactory } from "./msg-decoder/decoders";
import { ConsumerOffsetMsg, OffsetCommitMsgKey } from "./msg-decoder/data-structures";
import { MessageEntry } from "./aws-s3-indexer/types";
import { MessageSaverFactory } from "./aws-s3-indexer/MessageSaverFactory";

const INTERNAL_TOPIC = "__consumer_offsets";

const CLUSTER_NAME = process.env.MSK_CLUSTER_NAME;
const S3_DESTINATION_BASE_URL = process.env.S3_DESTINATION_BASE_URL;
const AWS_REGION = process.env.AWS_REGION || "eu-south-1";
const CONSUMER_GROUP_NAME = process.env.CONSUMER_GROUP_NAME || "consumer_offset-to-s3";

function decodedMessageToJson( decodedMessage: ConsumerOffsetMsg ) {
  return JSON.stringify(
    decodedMessage, 
    (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
  );
}

function isInternalTopicCommitMessage( decodedMessage: ConsumerOffsetMsg ) {
  let isInternalOffsetCommit = ( decodedMessage.kind === "OFFSET_COMMIT" );
  if( isInternalOffsetCommit ) {
    if( 'topic' in decodedMessage.key ) {
      const decodedMessageKey: OffsetCommitMsgKey = decodedMessage.key as OffsetCommitMsgKey;
      isInternalOffsetCommit = ( decodedMessageKey.topic == INTERNAL_TOPIC )
    }
    else {
      isInternalOffsetCommit = false;
    }
  }
  return isInternalOffsetCommit;
}

async function runConsumer() {

  const discovery = new MskDiscovery(AWS_REGION);
  if (!CLUSTER_NAME) {
    console.error("❌ Variabile MSK_CLUSTER_NAME mancante.");
    try {
        const clusters = await discovery.listAvailableClusters();
        console.log("LISTA DEI CLUSTER:")
        console.table(clusters);
    } catch(e) {
        console.error("❌ Errore Durante discovery cluster:", e);
    }
    process.exit(1);
  }

  if (!S3_DESTINATION_BASE_URL) {
    console.error("❌ Variabile S3_DESTINATION_BASE_URL mancante.");
    process.exit(1);
  }


  const msgDecoderFactory = ConsumerOffsetMsgDecodersFactory.getInstance$();
  const msgDecoder = msgDecoderFactory.getMsgDecoder();

  const msgSaverFactory = MessageSaverFactory.getInstance();
  const msgSaver = msgSaverFactory.getMessageSaver( S3_DESTINATION_BASE_URL );
  
  
  
  try {
    console.info(`--- Starting kafka cluster discovery for "${CLUSTER_NAME}" ---`);  
    const clusterArn = await discovery.getArnByClusterName(CLUSTER_NAME);
    const bootstrapServers = await discovery.getIamBootstrapBrokers(clusterArn);
    console.info(`- ClusterArn: ${clusterArn}`); 
    console.info(`- BootstrapServers: ${bootstrapServers}`); 

    console.info(`--- Starting kafka cluster connection, ...`);
    const kafka = new KafkaJS.Kafka({
      'bootstrap.servers': bootstrapServers,
      'security.protocol': "sasl_ssl",
      'sasl.mechanism': 'OAUTHBEARER',
      //"socket.timeout.ms": 30000,
      //'socket.connection.setup.timeout.ms': 30000,
      //'broker.address.family': 'v4',
      //'debug': 'broker,security,protocol',
      'oauthbearer_token_refresh_cb': async (args: any) => {
        console.log("🔑 [DEBUG] Richiesto nuovo token IAM...");
        const tokenData = await oauthBearerTokenProvider(AWS_REGION);
        console.log("🔑 [DEBUG] Token IAM generato con successo.");
        return tokenData;
      }
    });

    console.info(`  ... create consumer, ...`);
    const consumer = kafka.consumer({
      'group.id': CONSUMER_GROUP_NAME,
      'enable.auto.commit': false,
      'auto.offset.reset': 'earliest'
    });

    console.info(`  ... configure shutdown hook, ...`);
    const stop = async () => {
        console.log('Shutting down...');
        await consumer.disconnect();
        process.exit(0);
    };
    process.on('SIGINT', stop);
    process.on('SIGTERM', stop);

    console.info(`  ... connect consumer, ...`);
    await consumer.connect();
    console.info(`  ... done!`);

    console.info(`--- Start subscribe to topic ${INTERNAL_TOPIC} ...`);
    await consumer.subscribe({ topic: INTERNAL_TOPIC });
    console.info(` ... Done!`);

    console.info(`--- Start consume messages `);
    await consumer.run({
      eachBatch: async ({ batch, resolveOffset, heartbeat, isRunning, isStale }) => {
        
        console.info(` - Start handling a batch at partition ${batch.partition} ` 
                    + `at offset ${batch.firstOffset()} of length ${batch.messages.length}`);
        let lastOffsetsToCommit: { [ p: number ]: string } = {};
        
        const jsonMessages: MessageEntry[] = []
        for (const message of batch.messages) {
            if (!isRunning() || isStale()) break;

            const decodedMessage = msgDecoder.decodeMsg( batch, message );
            const messageJsonString = decodedMessageToJson( decodedMessage );
            
            const shouldCommit = ! isInternalTopicCommitMessage( decodedMessage );
            if (shouldCommit) {
                // console.log(`Processing message: ${messageJsonString}`);
                lastOffsetsToCommit[ batch.partition ] = message.offset;
            } else {
                console.log(`Skipping commit for message: ${messageJsonString}`);
            }
            jsonMessages.push( { json: messageJsonString, ts: message.timestamp } );

            await heartbeat();
        }
        
        await msgSaver.saveMessages( S3_DESTINATION_BASE_URL, jsonMessages );

        const offsetCommitsArray = 
          Object.entries( lastOffsetsToCommit )
          .map( ( partitionOffsetStringArray ) => {
            const partition = parseInt( partitionOffsetStringArray[0] );
            const nextOffset = (BigInt( partitionOffsetStringArray[1] ) + 1n).toString();
            const offsetCommitElement = { 
              topic: INTERNAL_TOPIC,
              partition,
              offset: nextOffset
            }
            return offsetCommitElement;
          });
        
        await consumer.commitOffsets( offsetCommitsArray);
      },
    });
  }
  catch (error) {
    console.error('Error in Kafka consumer:', error);
    throw error;
  }
}

runConsumer();

