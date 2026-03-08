package com.aryan.jip.content.service;

import com.aryan.jip.content.dto.QuestionDto;
import com.aryan.jip.content.dto.TopicDto;
import com.aryan.jip.content.dto.TopicSummaryDto;
import com.aryan.jip.content.model.Question;
import com.aryan.jip.content.model.Topic;
import com.aryan.jip.content.repository.QuestionRepository;
import com.aryan.jip.content.repository.TopicRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * Content Service — Interview questions and topic management
 *
 * Caching strategy (Cache-Aside pattern):
 *
 * topics:all         — all active topics list (TTL: 1h, rarely changes)
 * topics:{slug}      — single topic + questions (TTL: 30m)
 * questions:{id}     — individual question (TTL: 30m)
 *
 * Cache is evicted when ADMIN updates content via /api/admin/content/**
 *
 * Why Cache-Aside?
 * Application controls cache population. Simple to implement.
 * Alternative: Write-Through (update cache on every write) — more complex.
 * Cache-Aside is standard for read-heavy, infrequently changing data like
 * interview questions.
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(readOnly = true)
public class ContentService {

    private final TopicRepository topicRepo;
    private final QuestionRepository questionRepo;

    // ── Topics ────────────────────────────────────────────────────────────────

    @Cacheable(value = "topics", key = "'all'")
    public List<TopicSummaryDto> getAllTopics() {
        log.debug("Cache MISS — loading topics from DB");
        return topicRepo.findAllActiveSummaries();
    }

    @Cacheable(value = "topics", key = "#slug")
    public TopicDto getTopicBySlug(String slug) {
        log.debug("Cache MISS — loading topic '{}' from DB", slug);
        Topic topic = topicRepo.findBySlugWithQuestions(slug)
            .orElseThrow(() -> new RuntimeException("Topic not found: " + slug));
        return TopicDto.from(topic);
    }

    // ── Questions ─────────────────────────────────────────────────────────────

    @Cacheable(value = "questions", key = "#id")
    public QuestionDto getQuestion(UUID id) {
        Question q = questionRepo.findById(id)
            .orElseThrow(() -> new RuntimeException("Question not found: " + id));
        incrementViewCount(id);
        return QuestionDto.from(q);
    }

    public Page<QuestionDto> getByTopicAndDifficulty(
            String topicSlug,
            String difficulty,
            Pageable pageable) {

        return questionRepo
            .findByTopicSlugAndDifficulty(topicSlug, difficulty, pageable)
            .map(QuestionDto::from);
    }

    /**
     * Random questions for quiz generation.
     * Not cached — randomness defeats caching.
     */
    public List<Question> getRandomQuestionsForQuiz(String topicSlug, int count) {
        return questionRepo.findRandomByTopicSlug(topicSlug, count);
    }

    @Transactional
    public void incrementViewCount(UUID questionId) {
        questionRepo.incrementViewCount(questionId);
    }

    @CacheEvict(value = {"topics", "questions"}, allEntries = true)
    public void evictAllCaches() {
        log.info("All content caches evicted by admin action");
    }
}
