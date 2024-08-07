podman run -itd --name kafka_1 -p 9092:9092 -v ./kafka/config:/opt/kafka/config  -e PROCESS_ROLES=both -e CONTROLLER_QUORUM_VOTERS=broker1:9092,broker2:9092 apache/kafka:3.7.0
