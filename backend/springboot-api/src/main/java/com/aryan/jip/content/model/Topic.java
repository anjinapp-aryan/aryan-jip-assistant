package com.aryan.jip.content.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Topic — a major interview subject area (e.g. Java, Kafka, System Design)
 *
 * JPA relationship note:
 * OneToMany with LAZY fetch to avoid N+1 on topic list queries.
 * When individual topic detail is needed, questions are loaded via
 * a separate repository call or JOIN FETCH — not accidental lazy loading.
 */
@Entity
@Table(name = "topics",
    indexes = @Index(name = "idx_topics_slug", columnList = "slug")
)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Topic {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 100)
    private String name;  // e.g. "Java 21"

    @Column(unique = true, nullable = false, length = 100)
    private String slug;  // e.g. "java"

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(length = 50)
    private String icon;  // emoji or icon name

    @Column(name = "order_index")
    @Builder.Default
    private int orderIndex = 0;

    @Builder.Default
    @Column(name = "is_active")
    private boolean active = true;

    /**
     * LAZY fetch — explicit query when questions are needed.
     * Avoids the N+1 problem on /api/topics list endpoint.
     * Use @EntityGraph or JOIN FETCH for detail page.
     */
    @OneToMany(mappedBy = "topic", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    @Builder.Default
    private List<Question> questions = new ArrayList<>();
}
