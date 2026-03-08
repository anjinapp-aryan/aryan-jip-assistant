package com.aryan.jip.quiz.service;

import com.aryan.jip.content.model.Question;
import com.aryan.jip.content.service.ContentService;
import com.aryan.jip.quiz.dto.QuizResultDto;
import com.aryan.jip.quiz.dto.QuizStartRequest;
import com.aryan.jip.quiz.dto.QuizSubmitRequest;
import com.aryan.jip.quiz.model.QuizSession;
import com.aryan.jip.quiz.model.QuizAnswer;
import com.aryan.jip.quiz.repository.QuizSessionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Quiz Service — core quiz engine
 *
 * Flow:
 *  1. POST /api/quiz/start   → creates QuizSession, returns questions
 *  2. POST /api/quiz/submit  → grades answers, publishes Kafka event
 *
 * Kafka event published after quiz:
 *  Topic: quiz-events
 *  Payload: { userId, topicSlug, score, timestamp }
 *
 * Analytics module consumes this event asynchronously
 * → updates user mastery percentage per topic
 * → refreshes leaderboard in Redis
 *
 * This demonstrates event-driven decoupling:
 * Quiz module doesn't know about Analytics module.
 * They communicate only via Kafka events.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class QuizService {

    private final ContentService contentService;
    private final QuizSessionRepository sessionRepo;
    private final KafkaTemplate<String, String> kafkaTemplate;

    private static final String QUIZ_EVENTS_TOPIC = "quiz-events";
    private static final String PROGRESS_EVENTS_TOPIC = "progress-events";

    @Transactional
    public QuizSession startQuiz(UUID userId, QuizStartRequest request) {
        // Fetch random questions for the topic
        List<Question> questions = contentService.getRandomQuestionsForQuiz(
            request.getTopicSlug(),
            request.getQuestionCount()
        );

        QuizSession session = QuizSession.builder()
            .userId(userId)
            .topicSlug(request.getTopicSlug())
            .totalQuestions(questions.size())
            .build();

        session = sessionRepo.save(session);

        // Store question IDs in session for validation on submit
        QuizSession saved = session;
        saved.setQuestionIds(questions.stream()
            .map(q -> q.getId().toString())
            .toList());

        log.info("Quiz started: userId={}, topic={}, questions={}",
            userId, request.getTopicSlug(), questions.size());

        return sessionRepo.save(saved);
    }

    @Transactional
    public QuizResultDto submitQuiz(UUID userId, UUID sessionId, QuizSubmitRequest request) {
        QuizSession session = sessionRepo.findByIdAndUserId(sessionId, userId)
            .orElseThrow(() -> new RuntimeException("Quiz session not found"));

        if (session.isCompleted()) {
            throw new IllegalStateException("Quiz already submitted");
        }

        // Grade answers
        int correct = 0;
        for (QuizSubmitRequest.Answer submitted : request.getAnswers()) {
            Question question = contentService.getQuestion(submitted.getQuestionId()).toEntity();
            boolean isCorrect = submitted.getSelectedAnswer().equals(question.getAnswerText());
            if (isCorrect) correct++;

            session.getAnswers().add(QuizAnswer.builder()
                .session(session)
                .questionId(submitted.getQuestionId())
                .selectedAnswer(submitted.getSelectedAnswer())
                .correct(isCorrect)
                .build());
        }

        int score = (int) Math.round((double) correct / session.getTotalQuestions() * 100);
        session.setScore(score);
        session.setCorrectAnswers(correct);
        session.setCompleted(true);
        sessionRepo.save(session);

        // Publish event to Kafka — Analytics module will consume this
        publishQuizCompletedEvent(userId, session.getTopicSlug(), score);

        log.info("Quiz completed: userId={}, topic={}, score={}%",
            userId, session.getTopicSlug(), score);

        return QuizResultDto.builder()
            .sessionId(sessionId)
            .topicSlug(session.getTopicSlug())
            .score(score)
            .correctAnswers(correct)
            .totalQuestions(session.getTotalQuestions())
            .passed(score >= 60)
            .build();
    }

    private void publishQuizCompletedEvent(UUID userId, String topicSlug, int score) {
        try {
            // Simple JSON string payload (use Jackson ObjectMapper in production)
            String payload = String.format(
                "{\"event\":\"QUIZ_COMPLETED\",\"userId\":\"%s\",\"topicSlug\":\"%s\",\"score\":%d,\"ts\":%d}",
                userId, topicSlug, score, System.currentTimeMillis()
            );
            kafkaTemplate.send(QUIZ_EVENTS_TOPIC, userId.toString(), payload);
            log.debug("Published quiz-completed event for userId={}", userId);
        } catch (Exception e) {
            // Kafka failure must not fail the quiz submission
            // Pattern: Outbox pattern for guaranteed delivery in production
            log.error("Failed to publish quiz event (non-critical): {}", e.getMessage());
        }
    }
}
