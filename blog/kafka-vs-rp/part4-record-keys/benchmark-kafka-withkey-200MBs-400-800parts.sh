#!/usr/bin/env bash

echo "Writing workload files"

# ------- NOTES ---------------------
# 1. Make sure you have scaled up/out your client machines
#    for the number of clients in this test.
# 2. We want a longer warm-up to ensure that Kafka's
#    page cache is fully warmed up (i.e. it is full already).
#    else we can get a spurious latency which only occurs
#    on a cold system.

cat > workloads/benchmark-kafka-withkey-200MBs-400-800parts-step1.yaml << EOF
name: benchmark-kafka-withkey-200MBs-400-800parts-step1__AK-400part

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

cat > workloads/benchmark-kafka-withkey-200MBs-400-800parts-step2.yaml << EOF
name: benchmark-kafka-withkey-200MBs-400-800parts-step2__AK-800part

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

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-kafka-withkey-200MBs-400-800parts-step1.yaml \
workloads/benchmark-kafka-withkey-200MBs-400-800parts-step2.yaml


echo "Benchmark complete"
