
# Usage
This folder contains Dockerfile to build an application that connect to an 
[AWS MSK](https://aws.amazon.com/msk/) cluster, consume the ``__consumer_offsets`` topic
and save its content to an S3 bucket.

The container is configured with the following __environment variables__:
 - __KAFKA_BOOTSTRAP_SERVERS__: the bootstrap url of the kafka cluster to attach.
 - __S3_DESTINATION_BASE_URL__: ``s3://<bucket_name>/s3_keys_prefix`` where to save the 
   ``__consumer_offsets`` content; the S3 bucket must be in the AWS region specified with 
   the ``AWS_REGION`` environment variable.
 - __AWS_REGION__: the AWS region where the cluster and the container are deployed; 
   ``eu-south-1`` by default.
 - __CONSUMER_GROUP_NAME__: the name of the consumer group used by the application to memoize 
   which part of the ``__consumer_offsets`` topic was already dumped.
