#!/usr/bin/env bash

set -euo pipefail

echo "configuring sns/sqs"
echo "==================="
LOCALSTACK_HOST=localhost
AWS_REGION=us-east-1
LOCALSTACK_DUMMY_ID=000000000000

get_all_queues() {
    awslocal --endpoint-url=http://${LOCALSTACK_HOST}:4566 sqs list-queues
}

create_queue() {
  local QUEUE_NAME_TO_CREATE=$1
  awslocal --endpoint-url=http://${LOCALSTACK_HOST}:4566 sqs create-queue --queue-name ${QUEUE_NAME_TO_CREATE}
}

get_all_topics() {
  awslocal --endpoint-url=http://${LOCALSTACK_HOST}:4566 sns list-topics
}

create_topic() {
  local TOPIC_NAME_TO_CREATE=$1
  awslocal --endpoint-url=http://${LOCALSTACK_HOST}:4566 sns create-topic --name ${TOPIC_NAME_TO_CREATE}
}

link_queue_and_topic() {
  local TOPIC_ARN_TO_LINK=$1
  local QUEUE_ARN_TO_LINK=$2
  awslocal --endpoint-url=http://${LOCALSTACK_HOST}:4566 sns subscribe --topic-arn ${TOPIC_ARN_TO_LINK} --protocol sqs --notification-endpoint ${QUEUE_ARN_TO_LINK}
}

get_queue_arn_from_name() {
  local QUEUE_NAME=$1
  echo "arn:aws:sns:${AWS_REGION}:${LOCALSTACK_DUMMY_ID}:$QUEUE_NAME"
}

get_topic_arn_from_name() {
  local TOPIC_NAME=$1
  echo "arn:aws:sns:${AWS_REGION}:${LOCALSTACK_DUMMY_ID}:$TOPIC_NAME"
}

QUEUE_NAME="auth-local-queue"
TOPIC_NAME="auth-local-topic"

echo "creating topic $TOPIC_NAME"
TOPIC_CREATED_RESULT=$(create_topic ${TOPIC_NAME})
echo "created topic: $TOPIC_CREATED_RESULT"
AUTH_TOPIC_ARN=$(get_topic_arn_from_name $TOPIC_NAME)

echo "creating queue $QUEUE_NAME"
QUEUE_URL=$(create_queue ${QUEUE_NAME})
echo "created queue: $QUEUE_URL"
AUTH_QUEUE_ARN=$(get_queue_arn_from_name $QUEUE_NAME)

echo "linking topic $AUTH_TOPIC_ARN to queue $AUTH_QUEUE_ARN"
LINKING_RESULT=$(link_queue_and_topic $AUTH_TOPIC_ARN $AUTH_QUEUE_ARN)
echo "linking done:"
echo "$LINKING_RESULT"

QUEUE_NAME="syncing-server-local-queue"
TOPIC_NAME="syncing-server-local-topic"

echo "creating topic $TOPIC_NAME"
TOPIC_CREATED_RESULT=$(create_topic ${TOPIC_NAME})
echo "created topic: $TOPIC_CREATED_RESULT"
SYNCING_SERVER_TOPIC_ARN=$(get_topic_arn_from_name $TOPIC_NAME)

echo "creating queue $QUEUE_NAME"
QUEUE_URL=$(create_queue ${QUEUE_NAME})
echo "created queue: $QUEUE_URL"
SYNCING_SERVER_QUEUE_ARN=$(get_queue_arn_from_name $QUEUE_NAME)

echo "linking topic $SYNCING_SERVER_TOPIC_ARN to queue $SYNCING_SERVER_QUEUE_ARN"
LINKING_RESULT=$(link_queue_and_topic $SYNCING_SERVER_TOPIC_ARN $SYNCING_SERVER_QUEUE_ARN)
echo "linking done:"
echo "$LINKING_RESULT"

QUEUE_NAME="revisions-server-local-queue"
TOPIC_NAME="revisions-server-local-topic"

echo "creating topic $TOPIC_NAME"
TOPIC_CREATED_RESULT=$(create_topic ${TOPIC_NAME})
echo "created topic: $TOPIC_CREATED_RESULT"
REVISIONS_TOPIC_ARN=$(get_topic_arn_from_name $TOPIC_NAME)

echo "creating queue $QUEUE_NAME"
QUEUE_URL=$(create_queue ${QUEUE_NAME})
echo "created queue: $QUEUE_URL"
REVISIONS_QUEUE_ARN=$(get_queue_arn_from_name $QUEUE_NAME)

echo "linking topic $REVISIONS_TOPIC_ARN to queue $REVISIONS_QUEUE_ARN"
LINKING_RESULT=$(link_queue_and_topic $REVISIONS_TOPIC_ARN $REVISIONS_QUEUE_ARN)
echo "linking done:"
echo "$LINKING_RESULT"

echo "linking topic $SYNCING_SERVER_TOPIC_ARN to queue $REVISIONS_QUEUE_ARN"
LINKING_RESULT=$(link_queue_and_topic $SYNCING_SERVER_TOPIC_ARN $REVISIONS_QUEUE_ARN)
echo "linking done:"
echo "$LINKING_RESULT"

echo "all topics are:"
echo "$(get_all_topics)"

echo "all queues are:"
echo "$(get_all_queues)"
