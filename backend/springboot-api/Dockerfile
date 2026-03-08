# ──────────────────────────────────────────────────────────
# Multi-stage Dockerfile — Spring Boot Modular Monolith
#
# Stage 1: Build with Gradle (dependencies cached separately)
# Stage 2: Minimal JRE runtime (non-root user, optimized JVM)
# ──────────────────────────────────────────────────────────

# Stage 1 — Build
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

# Cache Gradle dependencies first (only re-runs if build files change)
COPY gradlew .
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true

# Build application JAR
COPY src/ src/
RUN ./gradlew bootJar -x test --no-daemon

# Extract layered JAR (optimizes subsequent Docker builds)
RUN java -Djarmode=layertools -jar build/libs/*.jar extract

# Stage 2 — Runtime
FROM eclipse-temurin:21-jre-alpine AS runtime

# Non-root user for security
RUN addgroup -S jip && adduser -S jip -G jip
WORKDIR /app

# Copy layered JAR contents (most stable layers first)
COPY --from=builder /build/dependencies/ ./
COPY --from=builder /build/spring-boot-loader/ ./
COPY --from=builder /build/snapshot-dependencies/ ./
COPY --from=builder /build/application/ ./

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1

USER jip

# JVM flags tuned for containers:
# -XX:MaxRAMPercentage=75 → use 75% of container memory limit
# -XX:+UseZGC → low-pause GC (Java 21 default for most workloads)
ENTRYPOINT ["java", \
    "-XX:MaxRAMPercentage=75.0", \
    "-XX:+UseZGC", \
    "-Djava.security.egd=file:/dev/./urandom", \
    "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE:-default}", \
    "org.springframework.boot.loader.launch.JarLauncher"]
