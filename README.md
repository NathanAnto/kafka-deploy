# Kafka Producer-Consumer Demo

This project demonstrates a simple Kafka producer and consumer using Python, orchestrated with Docker Compose.

## Setup

1. Ensure Docker and Docker Compose are installed.
2. Run `docker-compose up` to start Kafka and Zookeeper.
3. In separate terminals:
   - Run the producer: `python producer.py`
   - Run the consumer: `python consumer.py`

## Files

- `producer.py`: Sends messages to Kafka topic.
- `consumer.py`: Reads messages from Kafka topic.
- `docker-compose.yaml`: Defines Kafka and Zookeeper services.
- `Dockerfile.consumer`: Builds the consumer container (if needed).
- `requirements.txt`: Python dependencies (e.g., kafka-python).

## Usage

Messages sent by the producer will be received and printed by the consumer.