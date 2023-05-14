#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step1.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step1__RP-4prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 4
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step2.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step2__RP-10prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step3.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step3__RP-20prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 20
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step4.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step4__RP-40prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 40
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step5.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step5__RP-60prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 60
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step6.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step6__RP-80prod

topics: 1
partitionsPerTopic: 100
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 80
producerRate: 512000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step7.yaml << EOF
name: benchmark-withkey-500MBs-100parts-growing-producers-4-100-step7__RP-100prod

topics: 1
partitionsPerTopic: 100
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


echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step1.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step2.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step3.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step4.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step5.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step6.yaml \
workloads/benchmark-withkey-500MBs-100parts-growing-producers-4-100-step7.yaml

echo "Benchmark complete"
