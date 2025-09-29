### Demonstrating Kafka Brokers and Topics

To showcase Kafka's brokers (data storage nodes) and topics (message categories with partitions for parallelism), use your docker-compose setup (2 brokers). Start with `docker-compose up -d`. Demonstrate via CLI commands inside containers or Python scripts. Below are examples for different cluster structures.

#### 1. Single Broker Cluster (Simple Setup)

- **Purpose**: Show basic pub-sub without replication/fault tolerance.
- **Setup**: 
    - Modify `docker-compose.yaml` to run only one broker (comment out `kafka-2` service), restart.
- **Demo Steps**:
    - Create topic:  
        ```bash
        docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic single-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
        ```
    - Produce:  
        ```bash
        python producer.py single-topic
        ```
    - Consume:  
        ```bash
        py consumer.py single-topic group1
        ```
        ```bash
        py consumer.py single-topic group1
        ```
        (in two seperate terminals)
    - Observe: All messages go to one broker/partition; no redundancy.  
        ```bash
        kafka-topics.sh --describe --topic single-topic --bootstrap-server localhost:9092
        ```
        (shows 1 replica).
- **Use Case**: Development/testing environments or small-scale apps like a local logging system for a single microservice (e.g., a startup's internal metrics collector). No need for high availability; focuses on simplicity and low overhead.  
    Example: A solo developer's event stream for debugging app events.

#### 2. Multi-Broker Cluster (Scalability & Load Balancing)

- **Purpose**: Illustrate distribution across brokers for high throughput.
- **Setup**: 
    - Use your current 2-broker config (uncomment `kafka-2` if needed).
- **Demo Steps**:
    - Create topic:  
        ```bash
        docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic multi-topic --bootstrap-server localhost:9092 --partitions 2 --replication-factor 1
        ```
        (1 replica per partition, spread across brokers).
    - Produce 5 messages via `producer.py`:  
        ```bash
        python producer.py multi-topic
        ```
        (messages round-robin to partitions on different brokers).
    - Consume with group:  
        Run two consumers:  
        ```bash
        python consumer.py multi-topic group1
        ```
        in separate terminals; observe load balancing (each gets one partition).
    - Observe:  
        ```bash
        kafka-topics.sh --describe --topic multi-topic --bootstrap-server localhost:9092
        ```
        shows partitions on different brokers (e.g., P0 on broker 1, P1 on broker 2). Shut down one broker:  
        ```bash
        docker stop kafka-deploy-kafka-1
        ```
        Production stops, but consumption may continue on active partitions.
- **Use Case**: High-throughput scenarios without strict durability needs, like real-time analytics feeds (e.g., social media trend tracking where data can be recomputed if lost). Brokers distribute partitions for parallel processing.  
    Example: Streaming ad impressions across brokers for quick aggregation in a marketing platform.

#### 3. Replicated Multi-Broker Cluster (Fault Tolerance)

- **Purpose**: Demo high availability with replicas (leader/follower).
- **Setup**: 
    - Your 2-broker config supports `replication-factor 2`.
- **Demo Steps**:
    - Create replicated topic:  
        ```bash
        docker exec kafka-deploy-kafka-1 kafka-topics.sh --create --topic replicated-topic --bootstrap-server localhost:9092 --partitions 2 --replication-factor 2
        ```
    - Produce:  
        ```bash
        python producer.py replicated-topic
        ```
        (messages replicated to both brokers).
    - Consume:  
        ```bash
        python consumer.py replicated-topic group1
        ```
    - Failover:  
        Shut down leader broker:  
        ```bash
        docker stop kafka-deploy-kafka-1
        ```
        Produce more messages; observe new leader election (via logs):  
        ```bash
        docker logs kafka-deploy-kafka-2
        ```
        Restart and consume to see all messages.
    - Observe:  
        Describe topic shows 2 replicas per partition (one leader, one follower). Use Kafka UI (`localhost:8080`) to visualize brokers, topics, and replica status.
- **Use Case**: Mission-critical production systems requiring 99.99% uptime, such as financial transaction logs or e-commerce order processing (e.g., banking app where message loss could mean failed transfers). Replicas ensure failover.  
    Example: Ride-sharing apps like Uber using Kafka for ride requests, replicating across brokers to survive node failures.

#### Tips for Presentation

- Use `presentation.md`/HTML to add these steps with screenshots (e.g., topic describe output, UI views).
- Scale demo: Add more brokers in `docker-compose` for 3+ node cluster.
- Verify: Always run  
    ```bash
    kafka-topics.sh --list --bootstrap-server localhost:9092
    ```
    to list topics; monitor with Kafka UI.
- Edge Case: Show what happens without replication (messages lost on broker failure).