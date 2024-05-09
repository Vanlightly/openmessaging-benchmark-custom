#!/usr/bin/env python3
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

import glob
import json
import math
import argparse
import sys
import re

import pygal
from pygal.style import Style
from itertools import chain
from os import path
from jinja2 import Template
from collections import defaultdict

graph_colors = ['#545454', # dark gray
                '#e2401b', # redpanda red1
                '#78909c',  # light gray
                '#ED7F66', # redpanda red2
                '#0097A7', # blue
                '#ffab40', # yellow
                '#00ffff', # cyan
                '#ff00ff'] # magenta
chartStyle = Style(
    background='transparent',
    plot_background='transparent',
    font_family='googlefont:Montserrat',
    colors=graph_colors,
    label_font_size=16,
    legend_font_size=16,
    major_label_font_size=16,
)

# theme = pygal.style.CleanStyle
theme = chartStyle
fill = False
output = ''
charts = defaultdict(list)
coalesce = False


def _clean_xy_values(values):
    values = sorted((float(x), y) for x, y in values.items())
    # do not restrict to any percentiles. show the max; the outliers
    # are where the goodies lie

    def _x_axis(x):
        if x < 100.0: x = math.log10(100 / (100 - x))
        # clamp
        return min(x, 100.0)
 
    xy_values = [(_x_axis(x), y) for x, y in values]
    needle_idx = len(xy_values)-1
    while needle_idx > 0:
        x = round(xy_values[needle_idx][0],2)
        if x < 100.00:
            return xy_values[0:needle_idx]
        needle_idx = needle_idx-1
    return xy_values


def create_quantile_chart(title, y_label, y_max, time_series,
                          width, height):
    def _fmt_val(x):
        return 'p{:,.3f}'.format(100.0 - (100.0 / (10**x)))
    chart = pygal.XY(style=theme,
                     dots_size=2,
                     legend_at_bottom=True,
                     truncate_legend=37,
                     x_value_formatter=_fmt_val,
                     show_dots=True,
                     fill=fill,
                     stroke_style={'width': 2},
                     show_y_guides=True,
                     show_x_guides=True)
    chart.title = title
    chart.human_readable = True
    chart.y_title = y_label
    chart.x_title = 'Percentile'
    chart.x_labels = [0.31, 1, 3, 5]
    chart.x_label_rotation=20
    chart.x_labels_major_count=4
    chart.show_minor_x_labels=False
    chart.tooltip_border_radius=10

    if width > 0:
        chart.width=width
        chart.height=height

    if y_max > 0:
        labels = []
        val = 0
        while val <= y_max:
            labels.append(val)
            val += (y_max / 10)

        chart.y_labels = labels

    for label, values, opts in time_series:
        xy_values = _clean_xy_values(values)  
        chart.add(label, xy_values, stroke_style=opts)

    return chart

def create_quantile_chart_999(title, y_label, y_max, time_series,
                              width, height):
    def _fmt_val(x):
        return 'p{:,.3f}'.format(100.0 - (100.0 / (10**x)))
    chart = pygal.XY(style=theme,
                     dots_size=2,
                     legend_at_bottom=True,
                     truncate_legend=37,
                     x_value_formatter=_fmt_val,
                     show_dots=True,
                     fill=fill,
                     stroke_style={'width': 2},
                     show_y_guides=True,
                     show_x_guides=True)
    chart.title = title
    chart.human_readable = True
    chart.y_title = y_label
    chart.x_title = 'Percentile'
    chart.x_labels = [0.31, 1, 2, 3]
    chart.x_label_rotation=20
    chart.x_labels_major_count=4
    chart.show_minor_x_labels=False
    chart.tooltip_border_radius=10

    if width > 0:
        chart.width=width
        chart.height=height

    if y_max > 0:
        labels = []
        val = 0
        while val <= y_max:
            labels.append(val)
            val += (y_max / 10)

        chart.y_labels = labels

    for label, values, opts in time_series:

        xy_values = _clean_xy_values(values)
        chart.add(label, xy_values, stroke_style=opts)

    return chart

def create_quantile_chart_99(title, y_label, y_max, time_series,
                             width, height):
    def _fmt_val(x):
        return 'p{:,.3f}'.format(100.0 - (100.0 / (10**x)))
    chart = pygal.XY(style=theme,
                     dots_size=2,
                     legend_at_bottom=True,
                     truncate_legend=37,
                     x_value_formatter=_fmt_val,
                     show_dots=True,
                     fill=fill,
                     stroke_style={'width': 2},
                     show_y_guides=True,
                     show_x_guides=True)
    chart.title = title
    chart.human_readable = True
    chart.y_title = y_label
    chart.x_title = 'Percentile'
    chart.x_labels = [0.302, 0.603, 1.302, 2]
    chart.x_label_rotation=20
    chart.x_labels_major_count=4
    chart.show_minor_x_labels=False
    chart.tooltip_border_radius=10

    if width > 0:
        chart.width=width
        chart.height=height

    if y_max > 0:
        labels = []
        val = 0
        while val <= y_max:
            labels.append(val)
            val += (y_max / 10)

        chart.y_labels = labels

    for label, values, opts in time_series:

        xy_values = _clean_xy_values(values)
        chart.add(label, xy_values, stroke_style=opts)

    return chart

def create_multi_chart(title, y_label_1, y_label_2,
                       time_series):
    chart = pygal.XY(style=theme,
                     dots_size=2,
                     show_dots=True,
                     stroke_style={'width': 10},
                     stroke=True,
                     fill=fill,
                     legend_at_bottom=True,
                     show_x_guides=False,
                     show_y_guides=True)
    chart.title = title
    chart.human_readable = True
    chart.x_title = 'Time (seconds)'
    chart._y_title = y_label_1

    ys_1 = []
    ys_2 = []

    for label_1, values_1, label_2, values_2 in time_series:
        ys_1.append(values_1)
        chart.add(label_1, [(10 * x, y) for x, y in enumerate(values_1)])
        chart.add(label_2, [(10 * x, y) for x, y in enumerate(values_2)],
                  secondary=True)

    ys_1 = chain.from_iterable(ys_1)
    ys_2 = chain.from_iterable(ys_2)
    max_y_1 = float('-inf')  # Hack for starting w/ INT64_MIN
    max_y_2 = max_y_1
    for y in ys_1:
        if max_y_1 < y:
            max_y_1 = y
    chart.range = (0, max_y_1 * 1.20)
    return chart


def create_bar_chart(title, y_title, x_label, y_max, data):
    chart = pygal.Bar(style=theme,
                      dots_size=1,
                      show_dots=False,
                      stroke_style={'width': 2},
                      fill=fill,
                      show_legend=False,
                      x_label_rotation=25,
                      show_x_guides=False,
                      show_y_guides=True)
    chart.title = title
    chart.x_labels = x_label
    chart.y_title = y_title
    chart.value_formatter = lambda y: "{:,.0f}".format(y)

    for label, points in data.items():
        chart.add(label, points)

    if y_max > 0:
        chart.range = (0, y_max)

    return chart


def create_chart(title, y_title, y_max, time_series):
    chart = pygal.XY(style=theme,
                     dots_size=2,
                     show_dots=True,
                     stroke=True,
                     stroke_style={'width': 10},
                     fill=fill,
                     legend_at_bottom=True,
                     show_x_guides=False,
                     show_y_guides=True)
    chart.title = title

    chart.human_readable = True
    chart.y_title = y_title
    chart.x_title = 'Time (seconds)'

    ys = []
    for label, values in time_series:
        ys.append(values)
        chart.add(label, [(10 * x, y) for x, y in enumerate(values)])
    ys = chain.from_iterable(ys)

    if y_max > 0:
        chart.range = (0.0, float(y_max))
    else:
        max_y = float('-inf')  # Hack for starting w/ INT64_MIN
        for y in ys:
            if max_y < y:
                max_y = y

        chart.range = (max_y * 0.0, max_y * 1.20)


    return chart


def generate_charts(files, prod_y_max, con_y_max,
                    p100_y_max, p999_y_max, p99_y_max,
                    series_desc_type, only_throughput, lat_width,
                    lat_height):
    workloads = {}

    # Charts are labeled based on benchmark names, we need them
    # to be unique. A combination of (driver, workload) defines
    # a unique benchmark and name is "{driver}-{workload}".
    benchmark_names = set()
    for file in sorted(files):
        data = json.load(open(file))
        workload = data['workload']
        print(workload)

        series = ""

        if series_desc_type == "desc":
            # first look for a series description pattern
            series_search = re.search('.*__([\d\w-]+)', workload, re.IGNORECASE)
            series = ""
            if series_search:
                series = series_search.group(1)
            else:
                print("Regex failed to find a series description match in string " + workload)
                sys.exit()
        elif series_desc_type == "step":
            series_search = re.search('.*-(step\d+)', workload, re.IGNORECASE)
            if series_search:
                series = series_search.group(1)
            else:
                print("Regex failed to find a step match in string " + workload)
                sys.exit()
        else:
            series = workload

        unique_name = series
        # name used as chart label.
        name = series
        if unique_name in benchmark_names:
            print(f"WARN: Duplicate benchmark found: {name} in file {file}", file=sys.stderr)

        print("Adding " + unique_name)
        benchmark_names.add(unique_name)

        if coalesce:
            workload = 'All Workloads'
        else:
            workload = data['workload']

        benchmark_names.add(name)
        data['name'] = name

        if workload in workloads:
            workloads[workload].append(data)
        else:
            workloads[workload] = [data]

    for workload in workloads:
        stats_pub_rate = []
        stats_pub_rate_mbs = []
        stats_con_rate = []
        stats_con_rate_mbs = []
        stats_backlog = []
        stats_lat_p99 = []
        stats_lat_p999 = []
        stats_lat_p9999 = []
        stat_lat_avg = []
        stat_lat_max = []
        stat_lat_quantile = []
        stat_e2e_lat_quantile = []
        stat_e2e_lat_avg = []
        stat_e2e_lat_p50 = []
        stat_e2e_lat_p99 = []
        stat_e2e_lat_p9999 = []
        drivers = []

        pub_rate_avg = {}
        pub_rate_avg["Produce throughput (MB/s): higher is better"] = []

        con_rate_avg = {}
        con_rate_avg["Consume throughput (MB/s): higher is better"] = []

        # Aggregate across all runs
        count = 0
        curated_metrics = {}  # to dump to stdout
        metrics_of_interest = [
            "version",
            "beginTime",
            "endTime",
            "publishLatencyMin",
            "endToEndLatencyMin",
            "aggregatedPublishLatencyAvg",
            "aggregatedPublishLatency50pct",
            "aggregatedPublishLatency75pct",
            "aggregatedPublishLatency95pct",
            "aggregatedPublishLatency99pct",
            "aggregatedPublishLatencyMax",
            "aggregatedPublishDelayLatencyAvg",
            "aggregatedPublishDelayLatency50pct",
            "aggregatedPublishDelayLatency99pct",
            "aggregatedEndToEndLatencyAvg",
            "aggregatedEndToEndLatency50pct",
            "aggregatedEndToEndLatency75pct",
            "aggregatedEndToEndLatency95pct",
            "aggregatedEndToEndLatency99pct",
            "aggregatedEndToEndLatency9999pct",
            "aggregatedEndToEndLatencyMax",
        ]

        for data in workloads[workload]:
            metrics = dict()
            msg_size = data['messageSize']
            curated_metrics[data['name']] = metrics
            stats_pub_rate.append(data['publishRate'])
            stats_con_rate.append(data['consumeRate'])
            stats_backlog.append(data['backlog'])
            stats_lat_p99.append(data['publishLatency99pct'])
            stats_lat_p999.append(data['publishLatency999pct'])
            stats_lat_p9999.append(data['publishLatency9999pct'])
            stat_lat_avg.append(data['publishLatencyAvg'])
            stat_lat_max.append(data['publishLatencyMax'])

            stat_lat_quantile.append(data['aggregatedPublishLatencyQuantiles'])
            stat_e2e_lat_quantile.append(
                data['aggregatedEndToEndLatencyQuantiles'])
            stat_e2e_lat_avg.append(data['endToEndLatencyAvg'])
            stat_e2e_lat_p50.append(data['endToEndLatency50pct'])
            stat_e2e_lat_p99.append(data['endToEndLatency99pct'])
            stat_e2e_lat_p9999.append(data['endToEndLatency9999pct'])
            drivers.append(data['name'])

            prod_throughput = (sum(data['publishRate']) / len(data['publishRate']) * msg_size) / (1024 * 1024)
            pub_rate_avg["Produce throughput (MB/s): higher is better"].append({
                'value': prod_throughput,
                'color': graph_colors[count % len(graph_colors)]
            })

            consume_throughput = (sum(data['consumeRate']) / len(data['consumeRate']) * msg_size) / (1024 * 1024)
            con_rate_avg["Consume throughput (MB/s): higher is better"].append({
                'value': consume_throughput,
                'color': graph_colors[count % len(graph_colors)]
            })
            count = count + 1
            for metric_key in metrics_of_interest:
                if metric_key in data.keys():
                    metric_val = data[metric_key]
                    if metric_key in ('publishLatencyMin', 'endToEndLatencyMin'):
                       metric_val = min(metric_val)
                    metrics[metric_key] = metric_val
            metrics["prodThroughputMBps"] = prod_throughput
            metrics["consumeThroughputMBps"] = consume_throughput

        # OMB tooling depends on the output of this script, do not print extra stuff to stdout unless
        # you fully understand what you are doing.
        print(json.dumps(curated_metrics, indent=2))

        # Parse plot options
        opts = []
        if args.opts is None:
            for driver in drivers:
                opts.append({})
        else:
            for opt in args.opts:
                if opt == 'Dashed':
                    opts.append({'width': 4, 'dasharray': '3, 6, 12, 24'})
                else:
                    opts.append({})

        # Generate publish rate bar-chart
        charts[workload] = [create_bar_chart('Produce throughput (MB/s): higher is better', 'MB/s', drivers,
                                             prod_y_max, pub_rate_avg)]

        # Generate consume rate bar-chart
        charts[workload].append(create_bar_chart('Consume throughput (MB/s): higher is better', 'MB/s', drivers,
                                                 con_y_max, con_rate_avg))



        if not only_throughput:
            # Generate latency quantiles

            stat_plat_lat_quantile_99 = []
            for w in stat_lat_quantile:
                stat_lat_quantile_w = {}
                for quant, value in w.items():
                    if float(quant) <= 99.0:
                        stat_lat_quantile_w[quant] = value
                stat_plat_lat_quantile_99.append(stat_lat_quantile_w)

            time_series = zip(drivers, stat_plat_lat_quantile_99, opts)
            charts[workload].append(create_quantile_chart_99('Publish Latency Percentiles Up To 99: lower is better',
                                                          y_label='Latency (ms)',
                                                          y_max=p99_y_max,
                                                          time_series=time_series,
                                                          width=lat_width,
                                                          height=lat_height))


            stat_plat_lat_quantile_999 = []
            for w in stat_lat_quantile:
                stat_lat_quantile_w = {}
                for quant, value in w.items():
                    if float(quant) <= 99.9:
                        stat_lat_quantile_w[quant] = value
                stat_plat_lat_quantile_999.append(stat_lat_quantile_w)

            time_series = zip(drivers, stat_plat_lat_quantile_999, opts)
            charts[workload].append(create_quantile_chart_999('Publish Latency Percentiles Up To 99.9: lower is better',
                                                          y_label='Latency (ms)',
                                                          y_max=p999_y_max,
                                                          time_series=time_series,
                                                          width=lat_width,
                                                          height=lat_height))

            time_series = zip(drivers, stat_lat_quantile, opts)
            charts[workload].append(create_quantile_chart('Publish Latency Percentiles: lower is better',
                                                                  y_label='Latency (ms)',
                                                                  y_max=0,
                                                                  time_series=time_series,
                                                                  width=lat_width,
                                                                  height=lat_height))



            time_series = zip(drivers, stat_e2e_lat_quantile, opts)
            charts[workload].append(create_quantile_chart('End-to-End Latency Percentiles (all): lower is better',
                                          y_label='Latency (ms)',
                                          y_max=p100_y_max,
                                          time_series=time_series,
                                          width=lat_width,
                                          height=lat_height))

            stat_e2e_lat_quantile_999 = []
            for w in stat_e2e_lat_quantile:
                stat_e2e_lat_quantile_w = {}
                for quant, value in w.items():
                    if float(quant) <= 99.9:
                        stat_e2e_lat_quantile_w[quant] = value
                stat_e2e_lat_quantile_999.append(stat_e2e_lat_quantile_w)

            time_series = zip(drivers, stat_e2e_lat_quantile_999, opts)
            charts[workload].append(create_quantile_chart_999('End-to-End Latency Percentiles Up To 99.9: lower is better',
                                                          y_label='Latency (ms)',
                                                          y_max=p999_y_max,
                                                          time_series=time_series,
                                                          width=lat_width,
                                                          height=lat_height))

            stat_e2e_lat_quantile_99 = []
            for w in stat_e2e_lat_quantile:
                stat_e2e_lat_quantile_w = {}
                for quant, value in w.items():
                    if float(quant) <= 99.0:
                        stat_e2e_lat_quantile_w[quant] = value
                stat_e2e_lat_quantile_99.append(stat_e2e_lat_quantile_w)

            time_series = zip(drivers, stat_e2e_lat_quantile_99, opts)
            charts[workload].append(create_quantile_chart_99('End-to-End Latency Percentiles Up To 99: lower is better',
                                                              y_label='Latency (ms)',
                                                              y_max=p99_y_max,
                                                              time_series=time_series,
                                                              width=lat_width,
                                                              height=lat_height))

            # Generate p99 latency time-series
            time_series = zip(drivers, stats_lat_p99)
            charts[workload].append(create_chart('Publish Latency - 99th Percentile: lower is better',
                                                 y_title='Latency (ms)',
                                                 y_max=0,
                                                 time_series=time_series))

            # Generate avg E2E latency time-series
            time_series = zip(drivers, stat_e2e_lat_avg)
            charts[workload].append(create_chart('End-to-end Latency - Average: lower is better',
                                                 y_title='Latency (ms)',
                                                 y_max=0,
                                                 time_series=time_series))

            # Generate p50 E2E latency time-series
            time_series = zip(drivers, stat_e2e_lat_p50)
            charts[workload].append(create_chart('End-to-end Latency - P50: lower is better',
                                                 y_title='Latency (ms)',
                                                 y_max=0,
                                                 time_series=time_series))

            # Generate p99 E2E latency time-series
            time_series = zip(drivers, stat_e2e_lat_p99)
            charts[workload].append(create_chart('End-to-end Latency - P99: lower is better',
                                                 y_title='Latency (ms)',
                                                 y_max=0,
                                                 time_series=time_series))

            # Generate p99.99 E2E latency time-series
            time_series = zip(drivers, stat_e2e_lat_p9999)
            charts[workload].append(create_chart('End-to-end Latency - P99.99: lower is better',
                                                 y_title='Latency (ms)',
                                                 y_max=0,
                                                 time_series=time_series))

        # Generate publish rate
        time_series = zip(drivers, stats_pub_rate)
        charts[workload].append(create_chart('Publish Rate: higher is better',
                                             y_title='Message/s',
                                             y_max=(prod_y_max*1000),
                                             time_series=time_series))

        # Generate publish rate
        time_series = zip(drivers, stats_con_rate)
        charts[workload].append(create_chart('Consume Rate: higher is better',
                                             y_title='Message/s',
                                             y_max=(con_y_max*1000),
                                             time_series=time_series))

        # Generate consume + backlog rate
        labels_con = []
        labels_backlog = []

        for x in drivers:
            labels_con.append(x + " - Consume Rate")
            labels_backlog.append(x + " - Backlog")

        time_series = zip(labels_con, stats_con_rate, labels_backlog,
                          stats_backlog)
        charts[workload].append(create_multi_chart(
            'Consume rate (Messages/s - Left) w/ Backlog (No. of Messages - Right)',
            'Consume - Messages/s', 'Backlog - Messages', time_series))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Plot Kafka OpenMessaging Benchmark results')

    parser.add_argument(
        '--results',
        dest='results_dir',
        required=True,
        help='Directory containing the results for both Redpanda and Kafka')
    parser.add_argument('--series-opts',
                        nargs='+',
                        dest='opts',
                        required=False,
                        type=str,
                        help='Options for each series: Dashed or Filled')
    parser.add_argument('--output',
                        dest='output',
                        required=False,
                        type=str,
                        help='Location where all output will be stored')
    parser.add_argument('--coalesce-workloads',
                        dest='coalesce',
                        action='store_true',
                        help='Specify put all workloads on a single set of charts')

    parser.add_argument('--image-format',
                        dest='image_format',
                        required=False,
                        choices=['inline', 'svg', 'png'],
                        default='inline',
                        help='Specify put all workloads on a single set of charts')

    parser.add_argument('--produce-y-max',
                        dest='prod_y_max',
                        required=False,
                        type=int,
                        help='Specify a max y scale for produce throughput')

    parser.add_argument('--consume-y-max',
                        dest='con_y_max',
                        required=False,
                        type=int,
                        help='Specify a max y scale for consume throughput')

    parser.add_argument('--lat-chart-width',
                        dest='lat_width',
                        required=False,
                        type=int,
                        help='Specify a width for latency charts')

    parser.add_argument('--lat-chart-height',
                        dest='lat_height',
                        required=False,
                        type=int,
                        help='Specify a width for latency charts')

    parser.add_argument('--lat-all-y-max',
                        dest='lat_all_y_max',
                        required=False,
                        type=int,
                        help='Specify a max y scale for e2e latencies (all percentiles)')

    parser.add_argument('--lat-p999-y-max',
                        dest='lat_p999_y_max',
                        required=False,
                        type=int,
                        help='Specify a max y scale for e2e latencies (<= p99.9 percentiles)')

    parser.add_argument('--lat-p99-y-max',
                        dest='lat_p99_y_max',
                        required=False,
                        type=int,
                        help='Specify a max y scale for e2e latencies (<= p99 percentiles)')

    parser.add_argument('--series-desc-type',
                        dest='series_desc_type',
                        required=True,
                        type=str,
                        help='How to extract the series description: "series-desc", "step", "fullname"')

    parser.add_argument('--only-throughput',
                        dest='only_throughput',
                        required=False,
                        action='store_true',
                        help='Only generate the throughput charts')

    args = parser.parse_args()

    prefixes = {}

    if args.output != '':
        output = path.join(args.output, '')

    coalesce = args.coalesce

    image_format = args.image_format

    lat_width = args.lat_width
    if lat_width is None:
        lat_width = 0

    lat_height = args.lat_height
    if lat_height is None:
        lat_height = 0

    prod_y_max = args.prod_y_max
    if prod_y_max is None:
        prod_y_max = 0

    con_y_max = args.con_y_max
    if con_y_max is None:
        con_y_max = 0

    p100_y_max = args.lat_all_y_max
    if p100_y_max is None:
        p100_y_max = 0

    p999_y_max = args.lat_p999_y_max
    if p999_y_max is None:
        p999_y_max = 0

    p99_y_max = args.lat_p99_y_max
    if p99_y_max is None:
        p99_y_max = 0

    # Recursively fetch all json files in the results dir.
    filelist = glob.iglob(path.join(args.results_dir, "**/*.json"), recursive=True)

    generate_charts(filelist,
                    prod_y_max,
                    con_y_max,
                    p100_y_max,
                    p999_y_max,
                    p99_y_max,
                    args.series_desc_type,
                    args.only_throughput,
                    lat_width,
                    lat_height)

    html = '''
<html>
<head>
<script>
/*! pygal.js           2015-10-30 */
(function(){var a,b,c,d,e,f,g,h,i,j,k;i="http://www.w3.org/2000/svg",k="http://www.w3.org/1999/xlink",a=function(a,b){return null==b&&(b=null),b=b||document,Array.prototype.slice.call(b.querySelectorAll(a),0).filter(function(a){return a!==b})},e=function(a,b){return(a.matches||a.matchesSelector||a.msMatchesSelector||a.mozMatchesSelector||a.webkitMatchesSelector||a.oMatchesSelector).call(a,b)},h=function(a,b){return null==b&&(b=null),Array.prototype.filter.call(a.parentElement.children,function(c){return c!==a&&(!b||e(c,b))})},Array.prototype.one=function(){return this.length>0&&this[0]||{}},f=5,j=null,g=/translate\((\d+)[ ,]+(\d+)\)/,b=function(a){return(g.exec(a.getAttribute("transform"))||[]).slice(1).map(function(a){return+a})},c=function(c){var d,g,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H;for(a("svg",c).length?(o=a("svg",c).one(),q=o.parentElement,g=o.viewBox.baseVal,d=q.getBBox(),w=function(a){return(a-g.x)/g.width*d.width},x=function(a){return(a-g.y)/g.height*d.height}):w=x=function(a){return a},null!=(null!=(E=window.pygal)?E.config:void 0)?null!=window.pygal.config.no_prefix?l=window.pygal.config:(u=c.id.replace("chart-",""),l=window.pygal.config[u]):l=window.config,s=null,n=a(".graph").one(),t=a(".tooltip",c).one(),F=a(".reactive",c),y=0,B=F.length;B>y;y++)m=F[y],m.addEventListener("mouseenter",function(a){return function(){return a.classList.add("active")}}(m)),m.addEventListener("mouseleave",function(a){return function(){return a.classList.remove("active")}}(m));for(G=a(".activate-serie",c),z=0,C=G.length;C>z;z++)m=G[z],p=m.id.replace("activate-serie-",""),m.addEventListener("mouseenter",function(b){return function(){var d,e,f,g,h,i,j,k;for(i=a(".serie-"+b+" .reactive",c),e=0,g=i.length;g>e;e++)d=i[e],d.classList.add("active");for(j=a(".serie-"+b+" .showable",c),k=[],f=0,h=j.length;h>f;f++)d=j[f],k.push(d.classList.add("shown"));return k}}(p)),m.addEventListener("mouseleave",function(b){return function(){var d,e,f,g,h,i,j,k;for(i=a(".serie-"+b+" .reactive",c),e=0,g=i.length;g>e;e++)d=i[e],d.classList.remove("active");for(j=a(".serie-"+b+" .showable",c),k=[],f=0,h=j.length;h>f;f++)d=j[f],k.push(d.classList.remove("shown"));return k}}(p)),m.addEventListener("click",function(b,d){return function(){var e,f,g,h,i,j,k,l,m,n,o;for(g=a("rect",b).one(),h=""!==g.style.fill,g.style.fill=h?"":"transparent",m=a(".serie-"+d+" .reactive",c),i=0,k=m.length;k>i;i++)f=m[i],f.style.display=h?"":"none";for(n=a(".text-overlay .serie-"+d,c),o=[],j=0,l=n.length;l>j;j++)e=n[j],o.push(e.style.display=h?"":"none");return o}}(m,p));for(H=a(".tooltip-trigger",c),A=0,D=H.length;D>A;A++)m=H[A],m.addEventListener("mouseenter",function(a){return function(){return s=r(a)}}(m));return t.addEventListener("mouseenter",function(){return null!=s?s.classList.add("active"):void 0}),t.addEventListener("mouseleave",function(){return null!=s?s.classList.remove("active"):void 0}),c.addEventListener("mouseleave",function(){return j&&clearTimeout(j),v(0)}),n.addEventListener("mousemove",function(a){return!j&&e(a.target,".background")?v(1e3):void 0}),r=function(c){var d,e,g,m,n,o,p,r,s,u,v,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,$,_;for(clearTimeout(j),j=null,t.style.opacity=1,t.style.display="",G=a("g.text",t).one(),C=a("rect",t).one(),G.innerHTML="",v=h(c,".label").one().textContent,N=h(c,".x_label").one().textContent,J=h(c,".value").one().textContent,O=h(c,".xlink").one().textContent,D=null,q=c,I=[];q&&(I.push(q),!q.classList.contains("series"));)q=q.parentElement;if(q)for(X=q.classList,R=0,S=X.length;S>R;R++)if(g=X[R],0===g.indexOf("serie-")){D=+g.replace("serie-","");break}for(y=null,null!==D&&(y=l.legends[D]),o=0,u=[[v,"label"]],Y=J.split("\\n"),r=V=0,T=Y.length;T>V;r=++V)E=Y[r],u.push([E,"value-"+r]);for(l.tooltip_fancy_mode&&(u.push([O,"xlink"]),u.unshift([N,"x_label"]),u.unshift([y,"legend"])),H={},W=0,U=u.length;U>W;W++)Z=u[W],s=Z[0],z=Z[1],s&&(F=document.createElementNS(i,"text"),F.textContent=s,F.setAttribute("x",f),F.setAttribute("dy",o),F.classList.add(0===z.indexOf("value")?"value":z),0===z.indexOf("value")&&l.tooltip_fancy_mode&&F.classList.add("color-"+D),"xlink"===z?(d=document.createElementNS(i,"a"),d.setAttributeNS(k,"href",s),d.textContent=void 0,d.appendChild(F),F.textContent="Link >",G.appendChild(d)):G.appendChild(F),o+=F.getBBox().height+f/2,e=f,void 0!==F.style.dominantBaseline?F.style.dominantBaseline="text-before-edge":e+=.8*F.getBBox().height,F.setAttribute("y",e),H[z]=F);return K=G.getBBox().width+2*f,p=G.getBBox().height+2*f,C.setAttribute("width",K),C.setAttribute("height",p),H.value&&H.value.setAttribute("dx",(K-H.value.getBBox().width)/2-f),H.x_label&&H.x_label.setAttribute("dx",K-H.x_label.getBBox().width-2*f),H.xlink&&H.xlink.setAttribute("dx",K-H.xlink.getBBox().width-2*f),M=h(c,".x").one(),Q=h(c,".y").one(),L=parseInt(M.textContent),M.classList.contains("centered")?L-=K/2:M.classList.contains("left")?L-=K:M.classList.contains("auto")&&(L=w(c.getBBox().x+c.getBBox().width/2)-K/2),P=parseInt(Q.textContent),Q.classList.contains("centered")?P-=p/2:Q.classList.contains("top")?P-=p:Q.classList.contains("auto")&&(P=x(c.getBBox().y+c.getBBox().height/2)-p/2),$=b(t.parentElement),A=$[0],B=$[1],L+K+A>l.width&&(L=l.width-K-A),P+p+B>l.height&&(P=l.height-p-B),0>L+A&&(L=-A),0>P+B&&(P=-B),_=b(t),m=_[0],n=_[1],m===L&&n===P?c:(t.setAttribute("transform","translate("+L+" "+P+")"),c)},v=function(a){return j=setTimeout(function(){return t.style.display="none",t.style.opacity=0,null!=s&&s.classList.remove("active"),j=null},a)}},d=function(){var b,d,e,f,g;if(d=a(".pygal-chart"),d.length){for(g=[],e=0,f=d.length;f>e;e++)b=d[e],g.push(c(b));return g}},"loading"!==document.readyState?d():document.addEventListener("DOMContentLoaded",function(){return d()}),window.pygal=window.pygal||{},window.pygal.init=c,window.pygal.init_svg=d}).call(this);
</script>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css">
</head>
<body >
<div class="container">
<h1> {{title}} </h1>
  {% for workload in charts %}
    <div class='row'>
    <div class='well col-md-12'><h2>{{workload}}<h2></div>
    {% for chart in charts[workload] %}
      {% if image_format == 'inline' %}
        {{chart.render(disable_xml_declaration=True)}}
      {% else %}
        {% if image_format == 'svg' %}
            {% set fileName = output  + re.sub("[()-/ ]",'', workload + "-" + chart.title.split(":")[0]) + ".svg"
            | replace ("(","") %}
            {{ chart.render_to_file(fileName) or '' }}
            <div class="embed-responsive embed-responsive-4by3">
              <embed class=embed-responsive-item" type="image/svg+xml" src="{{ fileName }}"/>
            </div>
        {% else %}
            {% set fileName = output  + re.sub("[()-/ ]",'', workload + "-" + chart.title.split(":")[0]) + ".png"
            | replace ("(","") %}
            {{ chart.render_to_png(fileName) or '' }}
            <img src="{{ fileName }}" class="img-fluid"/>

        {% endif %}
      {% endif %}
    {% endfor %}
    <div>
  {% endfor %}
</div>
</body>
</html>
    '''

    template = Template(html)

    index_html = template.render(charts=charts, title="Charts", image_format=image_format, re=re, output=output)

    f = open(f"{output}index.html", "w")
    f.write(index_html)
    f.close()
