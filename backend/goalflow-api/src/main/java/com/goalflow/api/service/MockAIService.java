package com.goalflow.api.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

@Service
@Profile("mock")
public class MockAIService extends AIService {

    private static final Logger log = LoggerFactory.getLogger(MockAIService.class);

    @Value("${openai.api-key}")
    private String apiKey;

    @Value("${openai.base-url}")
    private String baseUrl;

    @Value("${openai.model}")
    private String model;

    // ObjectMapper and WebClient.Builder are inherited from AIService
    // and injected via the super constructor. No need to redeclare them.

    // Constructor to inject dependencies needed by the base class
    public MockAIService(ObjectMapper objectMapper, WebClient.Builder webClientBuilder) {
        super(objectMapper, webClientBuilder); // Call super constructor with dependencies
        // Fields apiKey, baseUrl, model are inherited and can be accessed directly or via super
        // if they were protected or public. For simplicity, assuming they are accessible.
    }

    @Override
    public List<List<String>> decomposeGoal(String name, String description, Integer totalDays, String taskCount) {
        log.info("Using MockAIService for goal decomposition.");
        List<List<String>> plan = new ArrayList<>();
        for (int i = 0; i < totalDays; i++) {
            plan.add(List.of("Mock Task 1 for day " + (i + 1), "Mock Task 2 for day " + (i + 1)));
        }
        return plan;
    }
}
