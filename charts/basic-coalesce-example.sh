#!/usr/bin/env bash

./generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--series-desc-type workload