#!/usr/bin/env bash

echo "Writing workload files"

# ----- BEFORE YOU RUN --------------
# Run for --entity-name 0, 1 and 2 for a three broker deployment.
# cd /opt/kafka/bin
# ./kafka-configs.sh --bootstrap-server localhost:9092 --alter \
#   --entity-type brokers --entity-name 0 \
#   --add-config log.retention.ms=10800000,log.retention.bytes=14000000000,retention.ms=10800000,retention.bytes=14000000000
# -----------------------------------

cat > workloads/benchmark-kafka-nullkey-1GBs-4-producers-3hr-ret-limit-step1.yaml << EOF
name: benchmark-kafka-nullkey-1GBs-4-producers-3hr-ret-limit-step1__AK-1000MBs-3hr-ret-limit

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 190
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-kafka-nullkey-1GBs-4-producers-3hr-ret-limit-step1.yaml

echo "Benchmark complete"
