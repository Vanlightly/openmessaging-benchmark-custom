#!/usr/bin/env bash

echo "Producer max=$1"
echo "Consumer max=$2"
echo "e2e latency all percentiles y-max=$3"
echo "e2e latency up to p99.9 percentiles y-max=$4"
echo "e2e latency up to p99 percentiles y-max=$5"

./generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--produce-y-max $1 \
--consume-y-max $2 \
--lat-all-y-max $3 \
--lat-p999-y-max $4 \
--lat-p99-y-max $5 \
--series-desc-type desc