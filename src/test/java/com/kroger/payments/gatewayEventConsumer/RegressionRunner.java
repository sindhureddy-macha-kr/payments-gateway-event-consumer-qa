package com.kroger.payments.gatewayEventConsumer;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import com.intuit.karate.junit5.Karate;
import org.junit.jupiter.api.BeforeAll;

public class RegressionRunner extends BaseTestRunner {
    @Test
    public void regressionTest() {
        String tag = "@regression";
        if (System.getProperty("task")!= null && !System.getProperty("task").isEmpty()) {
            tag = System.getProperty("task");
        }
        Results results = Runner.path("src/test/java/com/kroger/payments/gatewayEventConsumer/features")
                .outputJunitXml(true)
                .outputCucumberJson(true)
                .tags(tag)
                .parallel(2);
        generateReport(results.getReportDir());
        assertEquals(0, results.getFailCount());
        generateReport();
    }

}