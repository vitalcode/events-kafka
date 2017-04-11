#!/bin/bash

echo "Starting kafka"
${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_HOME}/config/kafka-server.properties &

# Test kafka
TEST_WAIT=0.2
TEST_TOPIC=test-topic2
TEST_MESSAGES_PATH=test-messages

pkill -9 -f ConsoleConsumer

cd $KAFKA_HOME
while bin/zookeeper-shell.sh $KAFKA_ZOOKEEPER_CONNECT get /brokers/ids/0 2>&1 | grep "Node does not exist"; do sleep $TEST_WAIT; echo "Waiting for Kafka to start"; done
echo "Kafka has started"

echo "Running Kafka smoke test"
echo "KZK $KAFKA_ZOOKEEPER_CONNECT"
# Delete test topic
bin/kafka-topics.sh --delete --topic $TEST_TOPIC --if-exists --zookeeper $KAFKA_ZOOKEEPER_CONNECT
while bin/kafka-topics.sh --list --topic $TEST_TOPIC --zookeeper $KAFKA_ZOOKEEPER_CONNECT | grep "$TEST_TOPIC"; do sleep $TEST_WAIT; echo "Waiting for $TEST_TOPIC deletion"; done

# Create test topic
bin/kafka-topics.sh --create --topic $TEST_TOPIC --if-not-exists  --zookeeper $KAFKA_ZOOKEEPER_CONNECT --replication-factor 1 --partitions 1
while ! bin/kafka-topics.sh --list --topic $TEST_TOPIC --zookeeper $KAFKA_ZOOKEEPER_CONNECT | grep "$TEST_TOPIC"; do sleep $TEST_WAIT; echo "Waiting for $TEST_TOPIC creation"; done

# Start message consumer and publish test messages
rm -f $TEST_MESSAGES_PATH
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic $TEST_TOPIC --from-beginning > $TEST_MESSAGES_PATH &

echo "first message" | bin/kafka-console-producer.sh --broker-list localhost:9092 --topic $TEST_TOPIC
echo "second message" | bin/kafka-console-producer.sh --broker-list localhost:9092 --topic $TEST_TOPIC

# Assert test messages
if [[ $(wc -l < $TEST_MESSAGES_PATH) -ne 2 ]]; then exit 1; fi

grep "first message" $TEST_MESSAGES_PATH
if [[ $? -ne 0 ]]; then exit 1; fi

grep "second message" $TEST_MESSAGES_PATH
if [[ $? -ne 0 ]]; then exit 1; fi

pkill -9 -f ConsoleConsumer
echo "Test completed successfully"

sleep infinity

