#!/usr/bin/env bash

echo "Writing workload files"

# Step 1
cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step1.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step1__AK-500MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 2
cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step2.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step2__AK-600MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 614400
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 3
cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step3.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step3__AK-700MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 716800
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

# Step 4
cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step4.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step4__AK-800MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 819200
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step5.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step5__AK-900MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 921600
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

cat > workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step6.yaml << EOF
name: benchmark-nullkey-500MBs-1GBs-50-producers-45min-step6__AK-1000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 50
producersPerTopic: 50
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 45
warmupDurationMinutes: 15
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step1.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step2.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step3.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step4.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step5.yaml \
workloads/benchmark-nullkey-500MBs-1GBs-50-producers-45min-step6.yaml

echo "Benchmark complete"
