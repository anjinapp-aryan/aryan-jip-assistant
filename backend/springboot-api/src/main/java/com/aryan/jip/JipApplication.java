package com.aryan.jip;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * Aryan JIP Assistant — Modular Monolith
 *
 * Architecture: Single deployable unit with clear internal module boundaries.
 *
 * Modules:
 *  - user        → registration, JWT auth, progress tracking
 *  - content     → interview questions, topics, explanations
 *  - quiz        → quiz sessions, scoring, results
 *  - systemdesign → architecture case studies
 *  - analytics   → Kafka-driven learning statistics
 *  - common      → shared config, security, utilities
 *
 * Why modular monolith over microservices?
 *  Simple to build, deploy, and run locally.
 *  Can extract into microservices later if needed.
 *  Right choice for a solo-buildable portfolio project.
 */
@SpringBootApplication
@EnableCaching
@EnableKafka
@EnableAsync
public class JipApplication {

    public static void main(String[] args) {
        SpringApplication.run(JipApplication.class, args);
    }
}
