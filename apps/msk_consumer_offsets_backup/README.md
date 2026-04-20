
# Usage
This folder contains Dockerfile to build an application that connect to an 
[AWS MSK](https://aws.amazon.com/msk/) cluster, consume the ``__consumer_offsets`` topic
and save its content to an S3 bucket.

The container is configured with the following __environment variables__:
 - __KAFKA_BOOTSTRAP_SERVERS__: the bootstrap URLs of the kafka cluster to attach.
 - __S3_DESTINATION_BUCKET_NAME__: The name of the S3 bucket where to store 
   ``__consumer_offsets`` topic backup. For implementation issue it have to be in 
   the region defined by ``AWS_REGION`` environment variable.
 - __S3_DESTINATION_PATH_PREFIX__: The S3 key prefix where to store ``__consumer_offsets`` 
   topic backup. 
 - __AWS_REGION__: the AWS region where the cluster and the container are deployed.
 - __CONSUMER_GROUP_NAME__: the name of the consumer group used by the application to memoize 
   which part of the ``__consumer_offsets`` topic was already dumped.
 - __SAVING_BATCH_SIZE__: number of message to put in a memory buffer before write them to
   persistent storage (currently S3) and commit kafka consumer group offsets.
 - __SAVING_BATCH_SECONDS__: maximum number of seconds between two persistent storage (currently S3) 
   saving and kafka consumer group offsets.
 - __TOPIC_STARTING_OFFSET__: The offset where to start to read ``__consumer_offsets`` topic; it can 
   be `earliest` or `latest`. Used only if the consumer group ``CONSUMER_GROUP_NAME`` is not 
   already present in the msk cluster. The default is `earliest`.
 - __JSON_LOGS__: If `true`, the logs are written in JSON format; plain text otherwise. 
   Default is `false`: logs are written as plain text.
 
 # Implementation
 Read [design.md file](./src/design.md)
 