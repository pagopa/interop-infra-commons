import { KafkaJS } from "@confluentinc/kafka-javascript";
import { Logger } from "pino";
import pino from 'pino';

import { oauthBearerTokenProvider } from "./aws-msk-utils/AuthProvider";
import { EachBatchPayload } from "@confluentinc/kafka-javascript/types/kafkajs";
import { ConsumerOffsetMessageHandler } from "./ConsumerOffsetsMessageHandler";

const INTERNAL_TOPIC = "__consumer_offsets";

const KAFKA_BOOTSTRAP_SERVERS = process.env.KAFKA_BOOTSTRAP_SERVERS;
const S3_DESTINATION_BASE_URL = process.env.S3_DESTINATION_BASE_URL;
const AWS_REGION = process.env.AWS_REGION || "eu-south-1";
const CONSUMER_GROUP_NAME = process.env.CONSUMER_GROUP_NAME;

const logger: Logger = pino();

async function runConsumer() {

  if (!KAFKA_BOOTSTRAP_SERVERS) {
    logger.error("❌ Variable KAFKA_BOOTSTRAP_SERVERS is required.");
    process.exit(1);
  }

  if (!S3_DESTINATION_BASE_URL) {
    logger.error("❌ Variable S3_DESTINATION_BASE_URL is required.");
    process.exit(1);
  }

  if (!CONSUMER_GROUP_NAME) {
    logger.error("❌ Variable CONSUMER_GROUP_NAME is required.");
    process.exit(1);
  }

  try {
    logger.info(`- BootstrapServers: ${KAFKA_BOOTSTRAP_SERVERS}`); 

    logger.info(`--- Starting kafka cluster connection, ...`);
    const kafka = new KafkaJS.Kafka({
      'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
      'security.protocol': "sasl_ssl",
      'sasl.mechanism': 'OAUTHBEARER',
      //"socket.timeout.ms": 30000,
      //'socket.connection.setup.timeout.ms': 30000,
      //'broker.address.family': 'v4',
      //'debug': 'broker,security,protocol',
      'oauthbearer_token_refresh_cb': async (args: any) => {
        logger.debug("Richiesto nuovo token IAM...");
        const tokenData = await oauthBearerTokenProvider(logger, AWS_REGION);
        logger.debug("Token IAM generato con successo.");
        return tokenData;
      }
    });

    logger.info(`  ... create consumer, ...`);
    const consumer = kafka.consumer({
      'group.id': CONSUMER_GROUP_NAME,
      'enable.auto.commit': false,
      'auto.offset.reset': 'earliest'
    });

    logger.info(`  ... configure shutdown hook, ...`);
    const stop = async () => {
        logger.info('Shutting down...');
        await consumer.disconnect();
        process.exit(0);
    };
    process.on('SIGINT', stop);
    process.on('SIGTERM', stop);

    logger.info(`  ... connect consumer, ...`);
    await consumer.connect();
    logger.info(`  ... done!`);

    logger.info(`--- Start subscribe to topic ${INTERNAL_TOPIC} ...`);
    await consumer.subscribe({ topic: INTERNAL_TOPIC });
    logger.info(` ... Done!`);

    logger.info(`--- Start consume messages `);
    const handler = new ConsumerOffsetMessageHandler( logger, AWS_REGION, INTERNAL_TOPIC, S3_DESTINATION_BASE_URL );
    
    await consumer.run({
      eachBatch: async ( payload: EachBatchPayload ) => {
        const offsetsToCommit = await handler.handleBatch( payload );
        await consumer.commitOffsets( offsetsToCommit );
      },
    });
  }
  catch (error) {
    logger.error('Error in Kafka consumer:' + (error as Error)?.message + "\n" + (error as Error)?.stack);
    throw error;
  }
}

runConsumer();

