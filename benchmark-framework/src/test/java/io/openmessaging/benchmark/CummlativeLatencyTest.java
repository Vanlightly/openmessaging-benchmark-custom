//package io.openmessaging.benchmark;
//
//import com.fasterxml.jackson.core.JsonProcessingException;
//import com.fasterxml.jackson.databind.DeserializationFeature;
//import com.fasterxml.jackson.databind.ObjectMapper;
//import com.fasterxml.jackson.databind.ObjectWriter;
//import io.netty.buffer.ByteBufUtil;
//import io.netty.buffer.Unpooled;
//import io.openmessaging.benchmark.worker.commands.CumulativeLatencies;
//import org.HdrHistogram.Histogram;
//import org.HdrHistogram.Recorder;
//import org.junit.Test;
//
//import java.nio.ByteBuffer;
//import java.util.Random;
//
//import static io.openmessaging.benchmark.worker.LocalWorker.E2ELatencyMaxHistoValue;
//import static org.junit.Assert.assertEquals;
//
//public class CummlativeLatencyTest {
//    private static final ObjectWriter writer = new ObjectMapper().writerWithDefaultPrettyPrinter();
//    private static final ObjectMapper mapper = new ObjectMapper()
//            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);
//
//    @Test
//    public void test() throws JsonProcessingException {
//        Random r = new Random();
//        Histogram endToEndLatency = new Histogram(E2ELatencyMaxHistoValue, 5);
//        Recorder recorder = new Recorder(E2ELatencyMaxHistoValue, 5);
//        for (int i=1; i<5; i++) {
//            for (long j = 0; j < 14400000L; j++) {
//                if (j == 10000000) {
//                    recorder.recordValue(100000000L);
//                }
//                recorder.recordValue(r.nextInt(1000000));
//            }
//
//            Histogram histo = recorder.getIntervalHistogram();
////            System.out.println(histo.getValueAtPercentile(50));
////            System.out.println(histo.getValueAtPercentile(99.99));
////            System.out.println(histo.getValueAtPercentile(99.999));
////            System.out.println(histo.getValueAtPercentile(100));
//            endToEndLatency.add(histo);
//        }
//
//        CumulativeLatencies stats = new CumulativeLatencies();
//        stats.endToEndLatency = endToEndLatency;
//
//        ByteBuffer histogramSerializationBuffer = ByteBuffer.allocate(1024 * 1024);
//        histogramSerializationBuffer.clear();
//        stats.endToEndLatency.encodeIntoCompressedByteBuffer(histogramSerializationBuffer);
//        stats.endToEndLatencyBytes = new byte[histogramSerializationBuffer.position()];
//        histogramSerializationBuffer.flip();
//        histogramSerializationBuffer.get(stats.endToEndLatencyBytes);
//
//        String serialized = writer.writeValueAsString(stats);
//        CumulativeLatencies finalStats = new CumulativeLatencies();
//
//
//        CumulativeLatencies deser = mapper.readValue(serialized, CumulativeLatencies.class);
//
//        for (int i=0; i<4; i++) {
//            try {
//                finalStats.endToEndLatency.add(Histogram.decodeFromCompressedByteBuffer(
//                        ByteBuffer.wrap(deser.endToEndLatencyBytes), E2ELatencyMaxHistoValue));
//            } catch (Exception e) {
//                System.out.println("Failed to decode end-to-end latency: {}" +
//                        ByteBufUtil.prettyHexDump(Unpooled.wrappedBuffer(deser.endToEndLatencyBytes)));
//                throw new RuntimeException(e);
//            }
//        }
//
//        System.out.println(stats.endToEndLatency.getValueAtPercentile(50));
//        System.out.println(stats.endToEndLatency.getValueAtPercentile(99.99));
//        System.out.println(stats.endToEndLatency.getValueAtPercentile(99.999));
//        System.out.println(stats.endToEndLatency.getValueAtPercentile(100));
//        System.out.println(finalStats.endToEndLatency.getValueAtPercentile(50));
//        System.out.println(finalStats.endToEndLatency.getValueAtPercentile(99.99));
//        System.out.println(finalStats.endToEndLatency.getValueAtPercentile(99.999));
//        System.out.println(finalStats.endToEndLatency.getValueAtPercentile(100));
//
//        assertEquals(stats.endToEndLatency.getValueAtPercentile(50),
//                finalStats.endToEndLatency.getValueAtPercentile(50));
//    }
//
//    @Test
//    public void test2() {
//        Histogram endToEndLatency = new Histogram(E2ELatencyMaxHistoValue, 5);
//        for (int i=0; i<10; i++) {
//            Recorder recorder = new Recorder(E2ELatencyMaxHistoValue, 5);
//            recorder.recordValue(1000001);
//            recorder.recordValue(1000002);
//            recorder.recordValue(1000002);
//            recorder.recordValue(60000);
//            recorder.recordValue(60000);
//            recorder.recordValue(10);
//            recorder.recordValue(10);
//
//            Histogram histo = recorder.getIntervalHistogram();
//            System.out.println(histo.getValueAtPercentile(50));
//            System.out.println(histo.getValueAtPercentile(75));
//            System.out.println(histo.getValueAtPercentile(99));
//            System.out.println(histo.getValueAtPercentile(100));
//
//            endToEndLatency.add(histo);
//        }
//
//        System.out.println(endToEndLatency.getValueAtPercentile(50));
//        System.out.println(endToEndLatency.getValueAtPercentile(75));
//        System.out.println(endToEndLatency.getValueAtPercentile(99));
//        System.out.println(endToEndLatency.getValueAtPercentile(100));
//    }
//}
