#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step1.yaml << EOF
name: benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step1__RP-1000MBs

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
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step2.yaml << EOF
name: benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step2__RP-1200MBs

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
warmupDurationMinutes: 10
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step1.yaml \
workloads/benchmark-nullkey-acks1-1000MBs-1200MBs-10-producers-no-ret-limit-step2.yaml

echo "Benchmark complete"
