package com.aryan.jip.content.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Entity
@Table(name = "questions",
    indexes = {
        @Index(name = "idx_q_topic", columnList = "topic_id"),
        @Index(name = "idx_q_difficulty", columnList = "difficulty")
    }
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "topic_id", nullable = false)
    private Topic topic;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String questionText;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String answerText;

    @Column(columnDefinition = "TEXT")
    private String codeExample;  // Java/SQL code snippet

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private Difficulty difficulty = Difficulty.MEDIUM;

    @Column(name = "is_quiz_eligible")
    @Builder.Default
    private boolean quizEligible = true;

    @Builder.Default
    @Column(name = "view_count")
    private int viewCount = 0;

    public enum Difficulty {
        EASY, MEDIUM, HARD, EXPERT
    }
}
