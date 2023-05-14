#!/usr/bin/env bash

echo "Writing workload files"

# --------- NOTES ------------
# Run this while monitoring the consumer lag.
# Ensure there is a data retention limit that is long
# enough to not interfere with the results. 3 hours is good.

cat > workloads/benchmark-kafka-backlog-drain-1000MB-5TB-backlog-fanout1-step1.yaml << EOF
name: benchmark-kafka-backlog-drain-1000MB-5TB-backlog-fanout1-step1

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 1024000
consumerBacklogSizeGB: 5000
testDurationMinutes: 1220
warmupDurationMinutes: 5
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-kafka-backlog-drain-1000MB-5TB-backlog-fanout1-step1.yaml

echo "Benchmark complete"
