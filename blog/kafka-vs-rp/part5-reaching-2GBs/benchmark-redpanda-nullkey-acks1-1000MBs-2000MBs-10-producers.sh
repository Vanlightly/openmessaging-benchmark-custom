#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step1.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step1__RP-1000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1024000
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step2.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step2__RP-1200MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1228800
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step3.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step3__RP-1400MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1433600
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step4.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step4__RP-1600MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1638400
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step5.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step5__RP-1800MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 1843200
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

cat > workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step6.yaml << EOF
name: benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step6__RP-2000MBs

topics: 1
partitionsPerTopic: 288
messageSize: 1024
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 10
producersPerTopic: 10
producerRate: 2048000
consumerBacklogSizeGB: 0
testDurationMinutes: 20
warmupDurationMinutes: 10
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-redpanda/redpanda_rf-3_acks-1_linger-1ms.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step1.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step2.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step3.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step4.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step5.yaml \
workloads/benchmark-redpanda-nullkey-acks1-1000MBs-2000MBs-10-producers-step6.yaml

echo "Benchmark complete"
