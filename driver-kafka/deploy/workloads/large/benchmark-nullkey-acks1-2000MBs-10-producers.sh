#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-nullkey-acks1-2000MBs-10-producers-step1.yaml << EOF
name: benchmark-nullkey-acks1-2000MBs-10-producers-step1__AK-2000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 2000000
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 10
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_acks-1_linger-1ms.yaml \
workloads/benchmark-nullkey-acks1-2000MBs-10-producers-step1.yaml

echo "Benchmark complete"
