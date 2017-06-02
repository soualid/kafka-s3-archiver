kafka-s3-archiver
========
Simple backup utility that read the raw content of a Kafka topic using a high level consumer group passed as parameter, stream the output to a daily rotated file, gzip and upload the resulting files to a given S3 bucket.

I use this to backup the content of our queue on S3 to be able to replay it after.

This utility uses the great **kafkacat** (https://github.com/edenhill/kafkacat).

# Example usage
```
docker run \
  -e WORKDIR=/temp/ \
  -e SERVER=server:port \
  -e REMOTE_BUCKET_PATH=s3://your.bucket.path/haproxy_logs/ \
  -e KAFKA_TOPIC=haproxy_logs \
  -e KAFKA_GROUP=log_archiver \
  -e AWS_ACCESS_KEY=xxx \
  -e AWS_SECRET=xxx \
  -v /recommended/local/path/to/external/volume:/temp \
  soualid/kafka-s3-archiver 
```
