import { z } from "zod";

const zodConfigObject = z
  .object({
    KAFKA_BOOTSTRAP_SERVERS: z.string(),
    S3_DESTINATION_BASE_URL: z.string(),
    AWS_REGION: z.string().default("eu-south-1"),
    CONSUMER_GROUP_NAME: z.string(),
    S3_SAVING_BATCH_SIZE: z.coerce.number().int().min(1).max(1000 * 1000),
    S3_SAVING_BATCH_SECONDS: z.coerce.number().int().min(60).max( 60 * 60 )
  })
  .transform((c) => ({
    kafkaBootstrapServers: c.KAFKA_BOOTSTRAP_SERVERS,
    s3DestinationBaseUrl: c.S3_DESTINATION_BASE_URL,
    awsRegion: c.AWS_REGION,
    consumerGroupName: c.CONSUMER_GROUP_NAME,
    s3SavingBatchSize: c.S3_SAVING_BATCH_SIZE,
    s3SavingBatchSeconds: c.S3_SAVING_BATCH_SECONDS,
  }));

export type ConsumersOffsetsDumperConfig = z.infer<typeof zodConfigObject>;
export const config: ConsumersOffsetsDumperConfig = zodConfigObject.parse(
  process.env
);
