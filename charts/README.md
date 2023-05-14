# Visualize results

You can create HTML files with individual charts for each json file, or you can combine the results of multiple json results into the same charts. Combining results is better for when you want see the relationships between workloads, configurations or other brokers.

## Chart prerequisites

Install the necessary Python packages.

```bash
python3 -m pip -r install requirements.txt
```

## Basic coalesce charts

Copy the result files into a directory and run the chart generation script:

```bash
cp path-to-results/*.json charts/results

cd charts
./generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--series-desc-type workload
```

This outputs throughput and latency charts to the `charts/output` directory, with the full workload names as the series legend names.

If you want some custom series names, then use the next technique.

## Using the `__description` method

To quickly produce charts with the series descriptions I want, I use a simple naming format (`__description`) for my workload names. For example, this two step benchmark has the series descriptions: AK-500MBs and AK-1000MBs.

```bash
#!/usr/bin/env bash

echo "Writing workload files"

cat > workloads/benchmark-500MBs-1GBs-50-producers-step1.yaml << EOF
name: benchmark-500MBs-1GBs-50-producers-step1__AK-500MBs

... etc
producersPerTopic: 50
producerRate: 512000
... etc
EOF

cat > workloads/benchmark-500MBs-1GBs-50-producers-step2.yaml << EOF
name: benchmark-500MBs-1GBs-50-producers-step2__AK-1000MBs

... etc
producersPerTopic: 50
producerRate: 1024000
... etc
EOF

echo "Starting benchmark"

sudo bin/benchmark -d driver-kafka/kafka_no-sync_rf-3_minisr-2_acks-all_linger-1ms.yaml \
workloads/benchmark-500MBs-1GBs-50-producers-step1.yaml \
workloads/benchmark-500MBs-1GBs-50-producers-step2.yaml

echo "Benchmark complete"
```
Run:
```bash
./generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--series-desc-type desc
```

It will take the series names from the `__description` pattern at the end of the workload names.

Sometimes I may have two different result sets that I do not want in the same charts, but I want them to share the same y-axis range so the bar charts and latency curves are easier to compare. You can achieve this via some addiitonal arguments.

For example, assuming my json files are located in `charts/results`:

```bash
./generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--series-desc-type desc \
--produce-y-max 500 \
--consume-y-max 500 \
--lat-all-y-max 2000 \
--lat-p999-y-max 1000 \
--lat-p99-y-max 300
```

The above ensures:
- Throughput charts have a y-axis range from 0 to 500 MB/s for produce and consume.
- All percentile end-to-end latency chart has a range from 0 to 2000ms.
- Up to p99.9 percentile end-to-end latency chart has a range from 0 to 1000ms.
- Up to p99 percentile end-to-end latency chart has a range from 0 to 300ms.

You can also control the size of the latency pcertile charts with the arguments: `--lat-chart-width 500 --lat-chart-height 500`.

These are simply the customizations that I have chosen for my own purposes. You can hack on the python scripts and add additional arguments.