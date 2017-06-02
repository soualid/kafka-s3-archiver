#!/bin/bash

# update aws creds
mkdir -p /root/.aws/ && \
  mkdir -p $WORKDIR && \
  echo -e "[default]\naws_access_key_id = $AWS_ACCESS_KEY\naws_secret_access_key = $AWS_SECRET" > /root/.aws/credentials 

cd /

echo Working directory: `pwd`
echo Directory content: `ls -1`

./backup.sh --workDir $WORKDIR --server $SERVER --remoteBucket $REMOTE_BUCKET_PATH --kafkaGroup $KAFKA_GROUP --kafkaTopic $KAFKA_TOPIC
