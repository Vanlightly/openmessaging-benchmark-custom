#!/usr/bin/env bash

echo "Writing workload files"

# ------- NOTES ---------------------
# 1. Make sure you have scaled up/out your client machines
#    for the number of clients in this test.

cat > workloads/benchmark-withkey-200MBs-400-800parts-step1.yaml << EOF
name: benchmark-withkey-200MBs-400-800parts-step1__RP-400part

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
warmupDurationMinutes: 60
EOF

cat > workloads/benchmark-withkey-200MBs-400-800parts-step2.yaml << EOF
name: benchmark-withkey-200MBs-400-800parts-step2__RP-800part

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
warmupDurationMinutes: 60
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-withkey-200MBs-400-800parts-step1.yaml \
workloads/benchmark-withkey-200MBs-400-800parts-step2.yaml


echo "Benchmark complete"
