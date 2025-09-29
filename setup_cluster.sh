#!/bin/bash

# Usage: ./setup_cluster.sh [single|multi|replicated] [topic-name]
# Defaults: demo-topic

set -e

CLUSTER_TYPE=${1:-single}
TOPIC=${2:-demo-topic}
BOOTSTRAP="localhost:9092"
REPLICATION_FACTOR=1  # Default for single

# Stop all services first
docker-compose down

# Backup original docker-compose.yaml if not exists
[ ! -f docker-compose.yaml.bak ] && cp docker-compose.yaml docker-compose.yaml.bak

case $CLUSTER_TYPE in
  single)
    REPLICATION_FACTOR=1
    # Restore original
    cp docker-compose.yaml.bak docker-compose.yaml
    # Comment out kafka-2 service block
    sed -i '/^  kafka-2:/,/^\s*$/s/^/# /' docker-compose.yaml
    # Adjust kafka-ui depends_on to remove kafka-2
    sed -i 's/      - kafka-2//g' docker-compose.yaml
    # Adjust quorum voters for single node (remove kafka-2 reference)
    sed -i 's/1@kafka:9093,2@kafka-2:9093/1@kafka:9093/g' docker-compose.yaml
    # Adjust KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS for UI
    sed -i 's/kafka:9092,kafka-2:9092/kafka:9092/g' docker-compose.yaml
    # Set offsets replication to 1 for single
    sed -i 's/KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=2/KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR=1/g' docker-compose.yaml
    sed -i 's/KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=2/KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1/g' docker-compose.yaml
    docker-compose up -d kafka kafka-ui
    sleep 30  # Wait longer for startup
    # Create internal __consumer_offsets topic
    docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic __consumer_offsets --bootstrap-server $BOOTSTRAP --partitions 50 --replication-factor $REPLICATION_FACTOR --config cleanup.policy=compact --if-not-exists || true
    # Create user topic
    docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic $TOPIC --bootstrap-server $BOOTSTRAP --partitions 1 --replication-factor $REPLICATION_FACTOR || true
    echo "export KAFKA_BOOTSTRAP_SERVERS=localhost:9092" > .env.cluster
    echo "Single broker cluster started for topic: $TOPIC"
    ;;
  multi|replicated)
    if [ "$CLUSTER_TYPE" = "multi" ]; then
      REPLICATION_FACTOR=1
    else
      REPLICATION_FACTOR=2
    fi
    # Restore original
    cp docker-compose.yaml.bak docker-compose.yaml
    docker-compose up -d
    sleep 30
    # Create internal __consumer_offsets topic
    docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic __consumer_offsets --bootstrap-server $BOOTSTRAP --partitions 50 --replication-factor 2 --config cleanup.policy=compact --if-not-exists || true
    # Create user topic
    docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic $TOPIC --bootstrap-server $BOOTSTRAP --partitions 2 --replication-factor $REPLICATION_FACTOR || true
    echo "export KAFKA_BOOTSTRAP_SERVERS=localhost:9092,localhost:9095" > .env.cluster
    if [ "$CLUSTER_TYPE" = "multi" ]; then
      echo "Multi-broker cluster (load balanced) started for topic: $TOPIC"
    else
      echo "Replicated multi-broker cluster started for topic: $TOPIC"
    fi
    ;;
  *)
    echo "Invalid type: use single, multi, or replicated"
    exit 1
    ;;
esac

echo "Source .env.cluster before running producer/consumer: source .env.cluster"
echo "Activate venv: source .venv/bin/activate"

# List topics and describe
docker exec kafka-deploy-kafka-1 kafka-topics.sh --list --bootstrap-server $BOOTSTRAP || true
docker exec kafka-deploy-kafka-1 kafka-topics.sh --describe --topic $TOPIC --bootstrap-server $BOOTSTRAP || true

echo "To reset to full cluster, run: cp docker-compose.yaml.bak docker-compose.yaml && docker-compose up -d"
