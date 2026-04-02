
# Usage
This folder contains Dockerfile to build an application that connect to an 
[AWS MSK](https://aws.amazon.com/msk/) cluster, consume the ``__consumer_offsets`` topic
and save its content to an S3 bucket.

The container is configured with the following __environment variables__:
 - __KAFKA_BOOTSTRAP_SERVERS__: the bootstrap URLs of the kafka cluster to attach.
 - __S3_DESTINATION_BASE_URL__: ``s3://<bucket_name>/s3_keys_prefix`` where to save the 
   ``__consumer_offsets`` content; the S3 bucket must be in the AWS region specified with 
   the ``AWS_REGION`` environment variable.
 - __AWS_REGION__: the AWS region where the cluster and the container are deployed; 
   ``eu-south-1`` by default.
 - __CONSUMER_GROUP_NAME__: the name of the consumer group used by the application to memoize 
   which part of the ``__consumer_offsets`` topic was already dumped.
 - __S3_SAVING_BATCH_SIZE__: number of message to put in a memory buffer before write them to
   S3 bucket and commit kafka consumer group offsets.
 - __S3_SAVING_BATCH_SECONDS__: maximum number of seconds between two S3 saving and kafka 
   consumer group offsets.
 