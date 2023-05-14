#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step1.yaml << EOF
name: benchmark-withkey-500MBs-288parts-growing-producers-50-400-step1__RP-50prod

topics: 1
partitionsPerTopic: 288
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 50
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step2.yaml << EOF
name: benchmark-withkey-500MBs-288parts-growing-producers-50-400-step2__RP-100prod

topics: 1
partitionsPerTopic: 288
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 100
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step3.yaml << EOF
name: benchmark-withkey-500MBs-288parts-growing-producers-50-400-step3__RP-200prod

topics: 1
partitionsPerTopic: 288
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 200
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step4.yaml << EOF
name: benchmark-withkey-500MBs-288parts-growing-producers-50-400-step4__RP-400prod

topics: 1
partitionsPerTopic: 288
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 400
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step1.yaml \
workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step2.yaml \
workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step3.yaml \
workloads/benchmark-withkey-500MBs-288parts-growing-producers-50-400-step4.yaml

echo "Benchmark complete"
