# Kafka benchmarks

There are two types of deployment:
1. Apache Kafka. See the `deploy/apache-kafka/DEPLOYMENT.md` file for instructions on how to deploy. The deployment automation is AWS-only but includes local-NVME and gp3 storage configurations.
2. Apache Kafka clients and third-party cluster. See the `deploy/clients-only/DEPLOYMENT.md` file for instructions on how to deploy.

See `BENCHMARKS.md` for instructions on how to run benchmarks and visualize the results.
See `WORKLOAD_DESIGN.md` for guidance on crafting workloads with OMB.