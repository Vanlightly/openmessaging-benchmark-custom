#!/usr/bin/env bash

echo "Writing workload files"

# --------- NOTES ------------
# Run this while monitoring the consumer lag.
# This is 1.6 TB per consumer group which - 5TB to OMB.
#
# Run this while monitoring the consumer lag.
# Ensure there is a data retention limit that is long
# enough to not interfere with the results. 3 hours is good.

cat > workloads/benchmark-backlog-drain-800MB-1.6TB-backlog-fanout3-step1.yaml << EOF
name: benchmark-backlog-drain-800MB-1.6TB-backlog-fanout3-step1

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 3
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 819200
consumerBacklogSizeGB: 5000
testDurationMinutes: 1220
warmupDurationMinutes: 5
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-backlog-drain-800MB-1.6TB-backlog-fanout3-step1.yaml

echo "Benchmark complete"
