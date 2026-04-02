import { KafkaJS } from "@confluentinc/kafka-javascript";
import { Logger } from "pino";
import pino from 'pino';

import { oauthBearerTokenProvider } from "./aws-msk-utils/AuthProvider";
import { EachBatchPayload } from "@confluentinc/kafka-javascript/types/kafkajs";
import { ConsumerOffsetMessageHandler } from "./ConsumerOffsetsMessageHandler";
import { config } from "./Config";

const INTERNAL_TOPIC = "__consumer_offsets";
const logger: Logger = pino();

async function runConsumer() {

  try {
    logger.info(`- BootstrapServers: ${config.kafkaBootstrapServers}`); 

    logger.info(`--- Starting kafka cluster connection, ...`);
    const kafka = new KafkaJS.Kafka({
      'bootstrap.servers': config.kafkaBootstrapServers,
      'security.protocol': "sasl_ssl",
      'sasl.mechanism': 'OAUTHBEARER',
      //"socket.timeout.ms": 30000,
      //'socket.connection.setup.timeout.ms': 30000,
      //'broker.address.family': 'v4',
      //'debug': 'broker,security,protocol',
      'oauthbearer_token_refresh_cb': async (args: any) => {
        logger.debug("Richiesto nuovo token IAM...");
        const tokenData = await oauthBearerTokenProvider(logger, config.awsRegion);
        logger.debug("Token IAM generato con successo.");
        return tokenData;
      }
    });

    logger.info(`  ... create consumer, ...`);
    const consumer = kafka.consumer({
      'group.id': config.consumerGroupName,
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
    const handler = new ConsumerOffsetMessageHandler( logger, INTERNAL_TOPIC, config );
    
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

