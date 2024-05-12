# Workload design

## Comparing unmanaged vs managed

Comparing two systems is hard to do well, especially unmanaged vs managed (SaaS).

Some things to take into account when comparing Apache Kafka to Confluent Cloud:

1. Confluent Cloud tiers data to S3, which requires some additional resources. Comparing Apache Kafka or Redpanda without tiered storage enabled vs Confluent Cloud is not totally apples-to-apples.
2. Converting CKUs to an equivalent in hardware, and vice-versa, is hard to get right. An apples-to-apples comparison can be hard to get right.

## Designing a workload

A workload file has the following most commonly used configs:

- `topics`: int
- `partitionsPerTopic`: int  
- `messageSize`: int e.g. 1024 as 1kb
- `keyDistributor`: ["NO_KEY", "KEY_ROUND_ROBIN", "RANDOM_NANO"]
- `payloadFile`: string, e.g. "payload/payload-1Kb.data"
- `subscriptionsPerTopic`: int
- `consumerPerSubscription`: omt
- `producersPerTopic`: int
- `producerRate`: int, e.g. 10 means 10 messages per second across all producers. It is the aggregate rate.
- `testDurationMinutes`: int
- `warmupDurationMinutes`: int

Some that are worthy of more detail, as follows.

### Warm-up duration (VERY IMPORTANT)

Kafka experiences its most volatile latency numbers in the first few minutes. When large disks are used, it can take up to 30 minutes to pass this volatile period where latency spikes can occur. These spikes are often down to the first disk flush that can take a few minutes to occur once a cluster is receiving load for the first time.

The following configs are important:
- `warmupDurationMinutes`. Defaults to 30 minutes.
- `warmupProducerRate`. Defaults to -1, and therefore the `producerRate`.
- `warmupProducerRateSeparationMinutes`. Leave some time between the warm-up ending and the beginning of the target workload. This can be important if the warm-up workload was much lower than the target workload. Defaults to 1 minute. Make it higher if you set the `warmupProducerRate` to be much lower than the `producerRate`.
- `testDurationMinutes`. The nummber of minutes the target workload should be run for. This does not include the warm-up.

### Record keys and keyDistributor config

Values:
  - When set to `NO_KEY`, the default partitioner is used. 
  - When set to `KEY_ROUND_ROBIN`, record keys are used. Each record that is sent is assigned an integer key value which is incremented each time. When it reaches 10000, it wraps around to 0.
  - When set to `RANDOM_NANO`, record keys are used. Each record that is sent is assigned an integer key value based on the nano time % 10000. Therefore like round robin, 10000 keys are used, but the distribution is random.

`KEY_ROUND_ROBIN` should produce a very balanced workload, whereas `RANDOM_NANO` should produce a slightly less uniform distribution.

### Consumer backlog drain tests and the consumerBacklogSizeGB config

Normally this is set to `0`. However, if you want to test consumer backlog drain tests, then set it to a value according to the `size of the total backlog / total number of subscriptions (aka consumer groups)`. The backlog is measured as the aggregate backlog across all subscriptions. So for example if you have a 5TB backlog (`consumerBacklogSizeGB: 5000`) and only one subscription (aka consumer group), then 5TB of records will build up. If you have two subscriptions, then 2.5 TB of records will build up, as the two subscriptions together have 5TB of backlog to drain.

When `consumerBacklogSizeGB > 0`, the consumers will pause until the backlog has built up, and then they will commence consumption. By default, the producers will build up the backlog using the `producerRate` config, but if you want the backlog to fill faster or slower than your target produce rate, then set the `backlogProducerRate` config.

### Message payloads

You can either use randomized payloads, or send the contents of a payload file. The benefit of payload files is that it places a lower CPU burden. But the randomized payloads given you more flexibility to test things like compression.

Either set `payloadFile` to point to a file in the `payloads` directory, or use the following:
- `useRandomizedPayloads: true`
- `randomBytesRatio: 0.5` as an example of 50% random
- `randomizedPayloadPoolSize: 10000`, as an example generates 10000 messages in a pool which are used when sending messages.

## Running multiple workloads and dimensional testing

In this repo, we use the workload file strategy where a single file creates multiple sub workload files to be executed one after the other.

For example, the following will run 2 benchmarks:

```
#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/10-50-topics-step1.yaml << EOF
name: 10-50-topics-step1__10topics

topics: 10
partitionsPerTopic: 10  
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 1
producersPerTopic: 4
producerRate: 1000
testDurationMinutes: 60
warmupDurationMinutes: 30
EOF

cat > workloads/10-50-topics-step2.yaml << EOF
name: 10-50-topics-step2__50topics

topics: 50
partitionsPerTopic: 10  
messageSize: 1024
keyDistributor: "KEY_ROUND_ROBIN"
payloadFile: "payload/payload-1Kb.data"
subscriptionsPerTopic: 1
consumerPerSubscription: 1
producersPerTopic: 4
producerRate: 1000
testDurationMinutes: 60
warmupDurationMinutes: 30
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/10-50-topics-step1.yaml \
workloads/10-50-topics-step2.yaml

echo "Benchmark complete"
```

You can choose a dimension (topics, partitions,producers, consumers, throughput etc), and run multiple tests in a row where you increase the dimension in each test.

For example, you may wish to measure latency for the throughputs:
- 10 MB/s
- 50 MB/s
- 150 MB/s
- 200 MB/s
- 250 MB/s

The chart generator can read the JSON result files and extract a workload label using the double underscore in the workload name. For example, `name: 10-50-topics-step2__50topics` will generate a series in the chart using `50topics`, instead of the longer workload name of `10-50-topics-step2`. See the charts README.md for details on that.

Take into account that OMB will run the workloads in lexigraphical order, therefore, for dimension tests, the step numbers help enforce the order.

## Interpreting results

The JSON result files are mostly self-explanatory. However, it is worth mentioning that you can track whether the producers were able to maintain the target rate or not by looking at the `publishDelayLatency` statistics. This measures the lag between the number of messages the producers have sent and the expected number. 

If producers fall behind the target briefly, this can be seen in:
- the timeline (`publishDelayLatencyAvg/50pct/75pct/.../9999pct/max`)
- the aggregated stats for the whole test, `aggregatedPublishLatencyAvg/50pct/75pct/.../9999pct/max`
- the more details percentiles, `aggregatedPublishDelayLatencyQuantiles`

### Comparing benchmarks

You can generate a single chart from multiple JSON result files that you want to compare. Place them all in the `charts/results` directory and generate a chart and it will include them all in one chart. See the charts README.md for more details.