# Architecture Documentation
## Aryan JIP Assistant

---

## Why Modular Monolith?

| Aspect | Microservices | Modular Monolith (chosen) |
|--------|--------------|--------------------------|
| Complexity | High — network calls, distributed tracing | Low — in-process calls |
| Deployment | Complex — orchestration needed | Simple — one Docker container |
| Buildable solo? | Difficult | ✅ Yes |
| Demonstrates architecture? | Yes | ✅ Yes, with clear module boundaries |
| Migration to microservices | Start here anyway | ✅ Extract when justified |

> "Build a monolith first. You can always extract microservices later — and you'll know exactly where the seams are."

The module boundaries are enforced by package structure. No circular dependencies between modules.

---

## Module Dependency Rules

```
user        ← standalone (no other module dependency)
content     ← standalone
quiz        → content (uses ContentService for questions)
systemdesign← standalone
analytics   → (Kafka only — no direct module import)
common      ← all modules depend on common config
```

Modules communicate via:
1. **Direct call** (same JVM): Quiz → ContentService
2. **Kafka events** (async): Quiz → Kafka → Analytics

---

## Database Design

```
users ─────────────────────────────────────────
  id (UUID PK)
  username, email (unique)
  password (BCrypt)
  role (USER | ADMIN)

topics ─────────────────────────────────────────
  id (UUID PK)
  name, slug (unique), icon, order_index

questions ──────────────────────────────────────
  id (UUID PK)
  topic_id (FK → topics)
  question_text, answer_text, code_example
  difficulty (EASY | MEDIUM | HARD | EXPERT)

quiz_sessions ──────────────────────────────────
  id (UUID PK)
  user_id (FK → users)
  topic_slug, total_questions, score, is_completed

quiz_answers ───────────────────────────────────
  id (UUID PK)
  session_id (FK → quiz_sessions)
  question_id (FK → questions)
  selected_answer, is_correct

user_progress ──────────────────────────────────
  user_id + topic_slug (composite unique)
  quizzes_taken, best_score, mastery_pct

system_design_cases ────────────────────────────
  id (UUID PK)
  title, slug, requirements, components
  database_design, caching_strategy, diagram_mermaid
```

---

## Redis Caching Strategy (Cache-Aside Pattern)

```
Application reads:
  1. Check Redis first
  2. If HIT → return cached value (fast, ~1ms)
  3. If MISS → read from DB → store in Redis → return

Cache invalidation:
  - TTL-based expiry (topics: 1h, questions: 30m)
  - Manual evict on admin content update

Cache keys:
  topics::all               → all topics list (TTL: 1h)
  topics::{slug}            → topic + questions (TTL: 30m)
  questions::{uuid}         → single question (TTL: 30m)
  leaderboard:global        → top users by score (TTL: 24h)
  leaderboard:{topic}       → per-topic leaderboard (TTL: 24h)
```

---

## Kafka Event Flow

```
User completes quiz
       │
       ▼
QuizService.submitQuiz()
       │
       ▼ kafkaTemplate.send("quiz-events", payload)
       │
   [kafka topic: quiz-events]
       │
       ▼ @KafkaListener(topics="quiz-events")
AnalyticsConsumer.onQuizCompleted()
       │
       ├── Update user_progress in PostgreSQL
       └── Update leaderboard in Redis (sorted set)

Decoupling benefit:
  - Quiz submission is never blocked by analytics
  - Analytics can replay events from Kafka offset
  - Analytics can be scaled independently
```

---

## JWT Authentication Flow

```
1. POST /api/auth/login
   → Validate credentials → BCrypt compare
   → Generate JWT (subject=username, role=USER, exp=1h)
   → Return { accessToken, expiresIn }

2. Subsequent requests:
   → Authorization: Bearer <token>
   → JwtAuthFilter intercepts before controllers
   → Validate signature, extract username
   → Load UserDetails from DB
   → Set Authentication in SecurityContext
   → Request proceeds to controller

3. Logout:
   → Add token to Redis blacklist (key=token, TTL=remaining lifetime)
   → JwtAuthFilter checks blacklist on each request
```

---

## Interview Talking Points

### "Why Redis for caching?"
Interview questions are read 1000x more than they're written. Cache-Aside with Redis reduces DB load by ~80%. We accept eventual consistency (30m TTL) since stale questions are acceptable — unlike financial data.

### "Why Kafka for analytics?"
Analytics should never block a user's quiz submission. Kafka decouples the producer (Quiz) from consumer (Analytics). If analytics is slow or down, the user flow is unaffected. Kafka's offset model also allows replaying events — invaluable for backfills.

### "Why not microservices?"
This is a solo portfolio project. Microservices add distributed tracing, network latency, service discovery, and operational complexity. The modular monolith has clear module boundaries that can be extracted later. Martin Fowler: "Don't start with microservices."

### "How would you scale this?"
1. Add read replica for PostgreSQL (questions are read-heavy)
2. Add Redis Cluster for cache (horizontal scaling)
3. Scale Kafka consumers independently (Analytics group)
4. Extract Quiz + Analytics to microservices if needed
5. Deploy behind NGINX or put behind AWS ALB
