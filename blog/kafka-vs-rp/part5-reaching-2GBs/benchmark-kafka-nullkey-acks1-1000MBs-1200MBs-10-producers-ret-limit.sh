#!/usr/bin/env bash

# run this with a 1 hour retention limit

echo "Writing workload files"

cat > workloads/benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1.yaml << EOF
name: benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1__AK-1000MBs-ret-limit

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 65
EOF

cat > workloads/benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2.yaml << EOF
name: benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2__AK-1200MBs-ret-limit

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1228800
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 65
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_acks-1_linger-1ms.yaml \
workloads/benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1.yaml \
workloads/benchmark-kafka-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2.yaml

echo "Benchmark complete"
