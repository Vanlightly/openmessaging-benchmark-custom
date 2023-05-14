#!/usr/bin/env bash

echo "Writing workload files"

# --------- NOTES ------------
# Run this while monitoring the consumer lag.
# This is 2.5 TB per consumer group which - 5TB to OMB.
#
# Run this while monitoring the consumer lag.
# Ensure there is a data retention limit that is long
# enough to not interfere with the results. 3 hours is good.

cat > workloads/benchmark-redpanda-backlog-drain-1000MB-2.5TB-backlog-fanout2-step1.yaml << EOF
name: benchmark-redpanda-backlog-drain-1000MB-2.5TB-backlog-fanout2-step1

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 2
consumerPerSubscription: 4
producersPerTopic: 4
producerRate: 1024000
consumerBacklogSizeGB: 5000
testDurationMinutes: 1220
warmupDurationMinutes: 5
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-redpanda-backlog-drain-1000MB-2.5TB-backlog-fanout2-step1.yaml

echo "Benchmark complete"
