package com.aryan.jip.analytics.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

/**
 * Analytics Kafka Consumer
 *
 * Consumes events from Quiz and User modules asynchronously.
 * Updates learning statistics without blocking the quiz flow.
 *
 * Event flow:
 *   Quiz module → kafka[quiz-events] → AnalyticsConsumer → PostgreSQL + Redis
 *
 * This is the event-driven architecture pattern:
 * - Producer (Quiz) doesn't know about Consumer (Analytics)
 * - Loose coupling via Kafka topic contract
 * - Consumer can be scaled independently
 * - Consumer can replay events from offset (Kafka retention)
 *
 * Interview talking point:
 * "We use Kafka for analytics to decouple learning stats from the
 *  quiz submission critical path. If analytics is slow, the user
 *  still gets their quiz result immediately."
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AnalyticsConsumer {

    private final UserProgressRepository progressRepo;
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;

    /**
     * Consumes quiz-events topic.
     * Manual acknowledgment ensures event is not lost if processing fails.
     * (requires spring.kafka.listener.ack-mode=manual in config)
     */
    @KafkaListener(
        topics = "quiz-events",
        groupId = "analytics-group",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void onQuizCompleted(
            @Payload String message,
            @Header(KafkaHeaders.RECEIVED_KEY) String key,
            Acknowledgment ack) {

        try {
            JsonNode event = objectMapper.readTree(message);
            String userId   = event.get("userId").asText();
            String topicSlug = event.get("topicSlug").asText();
            int score        = event.get("score").asInt();

            log.info("Analytics: quiz completed userId={} topic={} score={}",
                userId, topicSlug, score);

            // Update mastery in PostgreSQL
            progressRepo.upsertProgress(userId, topicSlug, score);

            // Update leaderboard in Redis (sorted set)
            // ZADD leaderboard <score> <userId>
            redisTemplate.opsForZSet().add("leaderboard:global", userId, score);

            // Per-topic leaderboard
            redisTemplate.opsForZSet().add(
                "leaderboard:" + topicSlug, userId, score);

            // Expire leaderboard after 24h (refresh daily)
            redisTemplate.expire("leaderboard:global", 24, TimeUnit.HOURS);

            // Acknowledge offset — mark as processed
            ack.acknowledge();

        } catch (Exception e) {
            log.error("Failed to process quiz event: {} — will retry", message, e);
            // Do NOT acknowledge → Kafka will redeliver
            // Add dead-letter topic in production for poison messages
        }
    }

    @KafkaListener(
        topics = "progress-events",
        groupId = "analytics-group"
    )
    public void onProgressUpdated(@Payload String message) {
        try {
            JsonNode event = objectMapper.readTree(message);
            log.debug("Progress event received: {}", event.get("event").asText());
            // Update aggregate learning stats
        } catch (Exception e) {
            log.error("Failed to process progress event: {}", e.getMessage());
        }
    }
}
