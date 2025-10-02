# Kafka Demo: Parallelism & Fault Tolerance

This guide demonstrates Kafka's core features using a 2-broker Docker setup and your Python scripts.

***

## Scenario 1: Basic Topic (1 Partition, 1 Replica)

**Goal:** Show a simple topic without parallelism or fault tolerance. Ideal for development.

1.  **Run Producer & Consumers:**
    ```bash
    # Start producer
    python producer.py test-1p-rf1
    
    # Start two consumers in separate terminals
    python consumer.py test-1p-rf1 group1
    python consumer.py test-1p-rf1 group1
    ```
**Observation:** Only **one consumer** receives messages. The other is idle because there is only one partition.

***

## Scenario 2: Scalability with Partitions (2 Partitions, 1 Replica) (might not demonstrate)

**Goal:** Demonstrate parallel processing via partitions, without fault tolerance. Best for high-throughput, non-critical tasks like analytics.

1.  **Run Producer & Consumers:**
    ```bash
    # Start two consumers for the same group
    python consumer.py test-2p-rf1 group2
    python consumer.py test-2p-rf1 group2

    # Start producer
    python producer.py test-2p-rf1
    ```
**Observation:** Messages are **load-balanced** across both consumers, demonstrating parallel processing.

2.  **Simulate Failure:**
    ```bash
    docker stop kafka-deploy-kafka-1
    ```
**Observation:** The partition on the stopped broker becomes unavailable, halting message flow for one consumer. This shows a **lack of fault tolerance**.

***

## Scenario 3: High Availability (2 Partitions, 2 Replicas)

**Goal:** Demonstrate automatic failover using replicas. Standard for mission-critical systems.

1.  **Run Producer & Consumer:**
    ```bash
    # Start consumer
    python consumer.py test-2p-rf2 group3

    # Start producer and let it run
    python producer.py test-2p-rf2
    ```
2.  **Simulate Failure:** While the producer is running, stop a broker.
    ```bash
    docker stop kafka-deploy-kafka-1
    ```
**Observation:** The producer and consumer pause briefly, then **recover automatically** as a new leader is elected for the offline partitions. **No data is lost**.