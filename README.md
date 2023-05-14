# Jack's custom OpenMessaging Benchmark Framework for his own benchmarking work

This is a slimmed down copy of OMB which I use for my own purposes but which may be useful for others. It contains some customizations around deployment, statistics and visualization.

Find the official OMB repository here: https://github.com/openmessaging/benchmark

Systems included:
- Apache Kafka in directory `driver-kafka`
- Redpanda in directory `driver-redpanda`

The following systems are included, but I have not run or made changes to these yet. They are currently aspirational projects for the future.
- Apache Pulsar `driver-pulsar`
- Apache BookKeeper `driver-bookkeeper`

Regarding Apache Kafka, if you run benchmarks in other OMB repositories, remember to upgrade Java to 17. It makes a difference.

## Future work

Make all these run on Kubernetes, without Helm, just the manifests (I just like it that way).
