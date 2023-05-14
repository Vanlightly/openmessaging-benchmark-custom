#!/usr/bin/env bash

# ----- BEFORE YOU RUN --------------
# rpk cluster config set delete_retention_ms 3600000
# -----------------------------------

echo "Writing workload files"

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1__RP-1000MBs-ret-limit

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 65
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2__RP-1200MBs-ret-limit

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1228800
consumerBacklogSizeGB: 0
testDurationMinutes: 30
warmupDurationMinutes: 65
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-all_linger-1ms.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step1.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-1200MBs-10-producers-ret-limit-step2.yaml

echo "Benchmark complete"
