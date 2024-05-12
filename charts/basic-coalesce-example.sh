#!/usr/bin/env bash

python3 generate_charts.py --results ./results \
--output ./output \
--coalesce-workloads \
--image-format png \
--series-desc-type desc