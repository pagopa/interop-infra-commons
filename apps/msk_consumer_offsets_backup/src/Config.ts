import { z } from "zod";

const zodConfigObject = z
  .object({
    KAFKA_BOOTSTRAP_SERVERS: z.string(),
    S3_DESTINATION_BUCKET_NAME: z.string(),
    S3_DESTINATION_PATH_PREFIX : z.string(),
    AWS_REGION: z.string(),
    CONSUMER_GROUP_NAME: z.string(),
    SAVING_BATCH_SIZE: z.coerce.number().int().min(1).max(1000 * 1000),
    SAVING_BATCH_SECONDS: z.coerce.number().int().min(60).max( 60 * 60 ),
    TOPIC_STARTING_OFFSET: z
      .union([z.literal("earliest"), z.literal("latest")])
      .default("earliest"),
    JSON_LOG: z.stringbool().default( false )
  })
  .transform((c) => ({
    kafkaBootstrapServers: c.KAFKA_BOOTSTRAP_SERVERS,
    s3DestinationBucketName: c.S3_DESTINATION_BUCKET_NAME,
    s3DestinationPathPrefix : c.S3_DESTINATION_PATH_PREFIX,
    awsRegion: c.AWS_REGION,
    consumerGroupName: c.CONSUMER_GROUP_NAME,
    savingBatchSize: c.SAVING_BATCH_SIZE,
    savingBatchSeconds: c.SAVING_BATCH_SECONDS,
    topicStartingOffset: c.TOPIC_STARTING_OFFSET,
    jsonLog: c.JSON_LOG
  }));

export type ConsumersOffsetsDumperConfig = z.infer<typeof zodConfigObject>;
export const config: ConsumersOffsetsDumperConfig = zodConfigObject.parse(
  process.env
);
