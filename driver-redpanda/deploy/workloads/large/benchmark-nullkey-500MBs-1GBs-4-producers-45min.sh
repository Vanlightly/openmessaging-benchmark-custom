#!/usr/bin/env bash

echo "Writing workload files"

# Step 1
cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step1.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step1__RP-500MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 2
cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step2.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step2__RP-600MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 614400
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 3
cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step3.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step3__RP-700MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 716800
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 4
cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step4.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step4__RP-800MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 819200
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step5.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step5__RP-900MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 921600
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

cat > workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step6.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-4-producers-45min-step6__RP-1000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step1.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step2.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step3.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step4.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step5.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-4-producers-45min-step6.yaml

echo "Benchmark complete"
