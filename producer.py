import time
import json
from kafka import KafkaProducer
import sys
import os

if len(sys.argv) != 2:
    print("Usage: python producer.py <topic-name>")
    sys.exit(1)
topic = sys.argv[1]

bootstrap_servers = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9093,localhost:9096').split(',')

# Create an instance of the Kafka producer
producer = KafkaProducer(
    bootstrap_servers=bootstrap_servers,
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

print("Sending messages...")
for i in range(1, 11):
    message = {'event_id': i, 'key': 'test', 'message': f'This is event number {i}'}
    
    # Send the message to the topic
    producer.send(topic, value=message)
    
    print(f"Sent: {message}")
    time.sleep(1) # Wait for 1 second before sending the next message

# Ensure all messages have been sent
producer.flush()
print("All messages sent.")