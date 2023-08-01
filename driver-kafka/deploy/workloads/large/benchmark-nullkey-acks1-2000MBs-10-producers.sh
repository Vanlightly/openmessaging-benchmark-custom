#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-nullkey-acks1-2000MBs-10-producers-step1.yaml << EOF
name: benchmark-nullkey-acks1-2000MBs-10-producers-step1__AK-2000MBs

topics: 3
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 5
producersPerTopic: 5
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 10
warmupDurationMinutes: 2
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_acks-1_linger-1ms.yaml \
workloads/benchmark-nullkey-acks1-2000MBs-10-producers-step1.yaml

echo "Benchmark complete"
