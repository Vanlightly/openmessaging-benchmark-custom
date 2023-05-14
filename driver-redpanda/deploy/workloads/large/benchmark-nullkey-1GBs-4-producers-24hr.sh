#!/usr/bin/env bash

echo "Writing workload files"

# Step 1
cat > workloads/benchmark-nullkey-1GBs-4-producers-24hr-step1.yaml << EOF
name: benchmark-nullkey-1GBs-4-producers-24hr-step1__RP-1000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 1440
warmupDurationMinutes: 60
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-nullkey-1GBs-4-producers-24hr-step1.yaml

echo "Benchmark complete"
