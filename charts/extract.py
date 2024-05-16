#!/usr/bin/env python3

import json
import argparse
import glob
import sys
import re
from os import path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Generate CSV from JSON results')

    parser.add_argument(
        '--results',
        dest='results_dir',
        required=True,
        help='Directory containing the JSON results')
    parser.add_argument(
            '--csv-file',
            dest='csv_file',
            required=True,
            help='The name of the CSV file to generate')
    args = parser.parse_args()

    print(args.results_dir)
    filelist = glob.iglob(path.join(args.results_dir, "**/*.json"), recursive=True)

    csv = open(args.csv_file, 'w')
    csv.write("Workload,WriteCaching,e2e-avg,e2e-p50,e2e-p75,e2e-p95,e2e-p99,e2e-p99.9,e2e-p99.99,e2e-max,pub-avg,pub-p50,pub-p75,pub-p95,pub-p99,pub-p99.9,pub-p99.99,pub-max\n")

    for file in filelist:
        # Opening JSON file
        f = open(file)

        # returns JSON object as
        # a dictionary
        data = json.load(f)
        f.close()

        series_search = re.search(r'.*__([\.\d\w-]+)', data["workload"], re.IGNORECASE)
        series = ""
        if series_search:
            series = series_search.group(1)
        else:
            print("Regex failed to find a series description match in string " + workload)
            series = "none"

        line = (f"{data["workload"]},"
                  f"{series},"
                  f"{data["aggregatedEndToEndLatencyAvg"]},"
                  f"{data["aggregatedEndToEndLatency50pct"]},"
                  f"{data["aggregatedEndToEndLatency75pct"]},"
                  f"{data["aggregatedEndToEndLatency95pct"]},"
                  f"{data["aggregatedEndToEndLatency99pct"]},"
                  f"{data["aggregatedEndToEndLatency999pct"]},"
                  f"{data["aggregatedEndToEndLatency9999pct"]},"
                  f"{data["aggregatedEndToEndLatencyMax"]},"
                  f"{data["aggregatedPublishLatencyAvg"]},"
                  f"{data["aggregatedPublishLatency50pct"]},"
                  f"{data["aggregatedPublishLatency75pct"]},"
                  f"{data["aggregatedPublishLatency95pct"]},"
                  f"{data["aggregatedPublishLatency99pct"]},"
                  f"{data["aggregatedPublishLatency999pct"]},"
                  f"{data["aggregatedPublishLatency9999pct"]},"
                  f"{data["aggregatedPublishLatencyMax"]}")
        csv.write(line + "\n")

    csv.close()
    print(f"Written results to {args.csv_file}")
