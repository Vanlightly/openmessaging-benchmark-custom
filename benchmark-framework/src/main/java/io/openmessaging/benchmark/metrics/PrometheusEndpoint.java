package io.openmessaging.benchmark.metrics;

import com.sun.net.httpserver.HttpServer;
import io.openmessaging.benchmark.utils.PaddingDecimalFormat;
import io.openmessaging.benchmark.worker.commands.PeriodStats;

import java.io.IOException;
import java.io.OutputStream;
import java.io.StringWriter;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.UnknownHostException;
import java.text.DecimalFormat;
import java.util.Random;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class PrometheusEndpoint {

    String hostname;
    PeriodStats periodStats;
    long scrapeDeadline = 0;
    Lock lock;
    private static final DecimalFormat rateFormat = new PaddingDecimalFormat("0.000", 7);
    private static final DecimalFormat dec = new PaddingDecimalFormat("0.000", 4);

    public PrometheusEndpoint() {
        this.hostname = getHost();
        this.lock = new ReentrantLock();
        this.periodStats = new PeriodStats();
        this.scrapeDeadline = 0;
    }

    public void reset() {
        lock.lock();
        try {
            this.periodStats = new PeriodStats();
            this.scrapeDeadline = 0;
        } finally {
            lock.unlock();
        }
    }

    public void updateStats(PeriodStats periodStats) {
        lock.lock();
        try {
            if (scrapeDeadline == 0) {
                scrapeDeadline = System.currentTimeMillis() + 120000;
            }

            // we ignore the first few scrapes in order to avoid bad stats
            // in the initial phase of the test.
            if (System.currentTimeMillis() > scrapeDeadline) {
                this.periodStats = periodStats;
            }
        } finally {
            lock.unlock();
        }
    }

    private String getHost() {
        try {
            return InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            return String.valueOf(new Random().nextInt(10000));
        }
    }

    public void run() {
        try {
            HttpServer server = HttpServer.create(new InetSocketAddress(9090), 0);
            server.createContext("/metrics", httpExchange -> {
                StringWriter writer = new StringWriter();
                lock.lock();
                try {
                    writer.write("client_messages_received_count{host=\"" + hostname + "\"} " + periodStats.totalMessagesReceived + "\n");
                    writer.write("client_messages_sent_count{host=\"" + hostname + "\"} " + periodStats.totalMessagesSent + "\n");
                    writer.write("client_bytes_sent_gauge{host=\"" + hostname + "\"} " + periodStats.bytesSent + "\n");
                    writer.write("client_bytes_sent_gauge{host=\"" + hostname + "\"} " + periodStats.bytesReceived + "\n");
                    writer.write("client_producer_errors_gauge{host=\"" + hostname + "\"} " + periodStats.errors + "\n");
                    writer.write("client_producer_timeout_errors_gauge{host=\"" + hostname + "\"} " + periodStats.timeoutErrors + "\n");
                    writer.write("client_consumer_errors_gauge{host=\"" + hostname + "\"} " + periodStats.pollErrors + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"50\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(50))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"75\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(75))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"90\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(90))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"95\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(95))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"99\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(99))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"99.9\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(99.9))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"99.99\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(99.99))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"99.999\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(99.999))) + "\n");
                    writer.write("client_e2e_latency{host=\"" + hostname + "\",percentile=\"100\"} " + dec.format(microsToMillis(periodStats.endToEndLatency.getValueAtPercentile(100))) + "\n");

                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"50\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(50))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"75\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(75))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"90\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(90))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"95\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(95))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"99\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"99.9\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.9))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"99.99\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.99))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"99.999\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.999))) + "\n");
                    writer.write("client_publish_latency{host=\"" + hostname + "\",percentile=\"100\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(100))) + "\n");

                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"50\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(50))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"75\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(75))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"90\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(90))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"95\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(95))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"99\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"99.9\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.9))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"99.99\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.99))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"99.999\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(99.999))) + "\n");
                    writer.write("client_publish_delay_latency{host=\"" + hostname + "\",percentile=\"100\"} " + dec.format(microsToMillis(periodStats.publishLatency.getValueAtPercentile(100))) + "\n");
                } finally {
                    lock.unlock();
                }

                String response = writer.toString();
                httpExchange.sendResponseHeaders(200, response.getBytes().length);
                try (OutputStream os = httpExchange.getResponseBody()) {
                    os.write(response.getBytes());
                }

            });

            Thread t = new Thread(server::start);
            t.setDaemon(true);
            t.start();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }

    }

    private double microsToMillis(long microTime) {
        return microTime / (1000.0);
    }
}
