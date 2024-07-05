# Lag exporter

## TODO:
- Include this in automation
- Make this work with TLS, or find an alternative.

## Installation

Copy the files to the Prometheus server, the scrape configs are already configured, just need to run lag exporter.

Once copied, update the bootstrap-brokers field to match the private IP addresses of the brokers. Then run the installation bash script.

It does not work with TLS.