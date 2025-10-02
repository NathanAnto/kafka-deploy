import json
import socket
import sys
import os
from kafka import KafkaConsumer

if len(sys.argv) != 3:
    print("Usage: python consumer.py <topic-name> <group-id>")
    sys.exit(1)

topic = sys.argv[1]
group_id = sys.argv[2]

bootstrap_servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9093,localhost:9096').split(',')

consumer = KafkaConsumer(
    topic,
    bootstrap_servers=bootstrap_servers,
    auto_offset_reset='earliest',
    group_id=group_id,
    value_deserializer=lambda v: json.loads(v.decode('utf-8'))
)

consumer_id = socket.gethostname()

print(f"Consumer {consumer_id} (group: {group_id}) waiting for messages...")
for message in consumer:
    print(f"Consumer {consumer_id} (group: {group_id}) received: {message.value}")