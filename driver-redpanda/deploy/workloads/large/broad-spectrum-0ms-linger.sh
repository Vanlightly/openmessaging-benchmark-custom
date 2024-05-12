#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/step01-nullkey-500MBs-4-producers-45min.yaml << EOF
name: step01-nullkey-500MBs-4-producers-45min__RP-500MBs-4prod

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

cat > workloads/step02-nullkey-1GBs-4-producers-45min.yaml << EOF
name: step02-nullkey-1GBs-4-producers-45min__RP-1000MBs-4prod

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

cat > workloads/step03-nullkey-500MBs-50-producers-45min.yaml << EOF
name: step03-nullkey-500MBs-50-producers-45min__RP-500MBs-50prod

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

cat > workloads/step04-nullkey-1GBs-50-producers-45min.yaml << EOF
name: step04-nullkey-1GBs-50-producers-45min__RP-1000MBs-50prod

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

cat > workloads/step05-withkey-50MBs-400parts-45min.yaml << EOF
name: step05-withkey-50MBs-400parts-45min__RP-50MBs-400part

topics: 40
partitionsPerTopic: 10
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 4
producerRate: 51200
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 15
EOF

cat > workloads/step06-withkey-50MBs-800parts-45min.yaml << EOF
name: step06-withkey-50MBs-800parts-45min__RP-50MBs-800part

topics: 80
partitionsPerTopic: 10
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 4
producerRate: 51200
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 15
EOF

cat > workloads/step07-withkey-200MBs-400parts-45min.yaml << EOF
name: step07-withkey-200MBs-400parts-45min__RP-200MBs-400part

topics: 40
partitionsPerTopic: 10
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 4
producerRate: 204800
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 15
EOF

cat > workloads/step08-withkey-200MBs-800parts-45min.yaml << EOF
name: step08-withkey-200MBs-800parts-45min__RP-200MBs-800part

topics: 80
partitionsPerTopic: 10
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 4
producerRate: 204800
consumerBacklogSizeGB: 0
testDurationMinutes: 60
warmupDurationMinutes: 15
EOF

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-0ms_small-batches.yaml \
workloads/step01-nullkey-500MBs-4-producers-45min.yaml \
workloads/step02-nullkey-1GBs-4-producers-45min.yaml \
workloads/step03-nullkey-500MBs-50-producers-45min.yaml \
workloads/step04-nullkey-1GBs-50-producers-45min.yaml \
workloads/step05-withkey-50MBs-400parts-45min.yaml \
workloads/step06-withkey-50MBs-800parts-45min.yaml \
workloads/step07-withkey-200MBs-400parts-45min.yaml \
workloads/step08-withkey-200MBs-800parts-45min.yaml
