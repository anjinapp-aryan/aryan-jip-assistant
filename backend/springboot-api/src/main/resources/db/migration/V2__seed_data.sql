-- ================================================================
-- V2__seed_data.sql
-- Topics + Sample Interview Questions + System Design Cases
-- ================================================================

-- ── Topics ─────────────────────────────────────────────────────
INSERT INTO topics (name, slug, description, icon, order_index) VALUES
('Java 21',              'java',            'Core Java, Collections, Multithreading, JVM, Records, Virtual Threads', '☕', 1),
('Spring Boot',          'spring-boot',     'Auto-configuration, DI, REST APIs, Actuator, Testing', '🌱', 2),
('Hibernate / JPA',      'hibernate',       'Entity mapping, relationships, N+1 problem, JPQL, caching', '🗄️', 3),
('Spring Security',      'spring-security', 'JWT, OAuth2, filter chain, RBAC, method security', '🔐', 4),
('SQL & Databases',      'sql',             'ACID, indexing, query optimization, transactions, normalization', '💾', 5),
('Microservices',        'microservices',   'Service decomposition, patterns, circuit breaker, API gateway', '🔧', 6),
('Apache Kafka',         'kafka',           'Topics, partitions, consumer groups, exactly-once, streams', '📨', 7),
('System Design',        'system-design',   'URL shortener, Netflix, Uber, WhatsApp — end-to-end design', '📐', 8),
('AWS Concepts',         'aws',             'EC2, S3, RDS, SQS, Lambda, EKS — architecture concepts', '☁️', 9),
('React JS',             'react',           'Hooks, state management, performance, component patterns', '⚛️', 10);

-- ── Java Questions ─────────────────────────────────────────────
INSERT INTO questions (topic_id, question_text, answer_text, code_example, difficulty) VALUES

((SELECT id FROM topics WHERE slug='java'),
'How does HashMap work internally in Java?',
'HashMap uses an array of Node<K,V>[] (buckets). On put(key, value):
1. hashCode() is called on key → hash computed → index = (n-1) & hash
2. If bucket empty → store node directly
3. If collision → nodes form a linked list; Java 8+ converts to Red-Black Tree when list size > 8 (TREEIFY_THRESHOLD)
4. When size > capacity × loadFactor (default 0.75) → resize: double capacity, rehash all entries

Key interview points:
- Default capacity: 16, max load factor: 0.75
- HashMap is NOT thread-safe → use ConcurrentHashMap for concurrent access
- ConcurrentHashMap uses bucket-level CAS locking (not full-map sync like Hashtable)
- null key is allowed and maps to index 0',
'// Internal structure insight
Map<String, Integer> map = new HashMap<>(16, 0.75f);
map.put("Java", 1);
// Key "Java" → hashCode() → index in Node[] table

// Thread-safe alternative
Map<String, Integer> concurrent = new ConcurrentHashMap<>();
concurrent.put("key", 1); // CAS-based locking per bucket

// Java 21 — use Sequenced collections
SequencedMap<String, Integer> seq = new LinkedHashMap<>();',
'HARD'),

((SELECT id FROM topics WHERE slug='java'),
'What are Java Virtual Threads (Project Loom) and when to use them?',
'Virtual Threads (Java 21 GA) are lightweight threads managed by the JVM, not the OS.

Platform threads: OS-managed, expensive (~1MB stack), typically pooled (ExecutorService)
Virtual threads: JVM-managed, cheap (~few KB), can create millions

Key concepts:
- Virtual threads are mounted on carrier (platform) threads
- When a virtual thread blocks (I/O, sleep), it is UNMOUNTED from carrier thread
- Carrier thread picks up another runnable virtual thread → better CPU utilization
- No need for reactive/async programming for I/O-bound workloads

When to use: I/O-bound tasks (HTTP calls, DB queries, file I/O)
When NOT to use: CPU-bound tasks (no benefit, same as platform threads)

Important: synchronized blocks pin virtual threads to carrier → prefer ReentrantLock',
'// Java 21 — Virtual Threads
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    // Create 10,000 virtual threads cheaply
    IntStream.range(0, 10_000).forEach(i ->
        executor.submit(() -> {
            Thread.sleep(Duration.ofMillis(100)); // does not block carrier!
            return fetchDataFromDB(); // I/O — yields carrier thread
        })
    );
}

// Spring Boot 3.2 — enable virtual threads
// application.properties: spring.threads.virtual.enabled=true

// Use ReentrantLock instead of synchronized with virtual threads
ReentrantLock lock = new ReentrantLock();
lock.lock(); // does NOT pin virtual thread
try { criticalSection(); } finally { lock.unlock(); }',
'EXPERT'),

((SELECT id FROM topics WHERE slug='java'),
'Explain the difference between Comparable and Comparator',
'Comparable: natural ordering — class implements it to define its own sort order.
Comparator: external ordering — separate class/lambda defining alternative ordering.

Rule: use Comparable for the "default" order (e.g. Employee by ID).
Use Comparator for flexible/alternative ordering without modifying the class.',
'// Comparable — natural ordering
class Employee implements Comparable<Employee> {
    private int id;
    private String name;

    @Override
    public int compareTo(Employee other) {
        return Integer.compare(this.id, other.id); // natural: sort by ID
    }
}

// Comparator — external, flexible
Comparator<Employee> byName   = Comparator.comparing(Employee::getName);
Comparator<Employee> byNameDesc = byName.reversed();
Comparator<Employee> byDeptThenName = Comparator
    .comparing(Employee::getDept)
    .thenComparing(Employee::getName);

List<Employee> employees = getEmployees();
employees.sort(byDeptThenName);
Collections.sort(employees); // uses Comparable (natural order = by ID)',
'MEDIUM'),

-- ── Kafka Questions ────────────────────────────────────────────
((SELECT id FROM topics WHERE slug='kafka'),
'What is Kafka''s exactly-once semantics and how is it achieved?',
'Exactly-once semantics (EOS) ensures each message is processed exactly once, even with failures.

Three delivery guarantees:
- At-most-once: may lose messages (acks=0)
- At-least-once: may duplicate (acks=all, no idempotence) — default
- Exactly-once: no loss, no duplication — requires configuration

EOS components:
1. Idempotent Producer: enable.idempotence=true
   → Producer assigns sequence numbers; broker deduplicates retries
2. Transactional Producer: wraps multiple sends in one atomic transaction
3. Consumer isolation.level=read_committed
   → Consumer only reads messages from committed transactions

Cost: ~20% throughput reduction. Use only when required (financial transactions, order processing).',
'// Idempotent Producer (prevents duplicate sends on retry)
Properties props = new Properties();
props.put("enable.idempotence", "true");
props.put("acks", "all");
props.put("retries", Integer.MAX_VALUE);

// Transactional Producer (atomic multi-message send)
props.put("transactional.id", "order-processor-1");
KafkaProducer<String, String> producer = new KafkaProducer<>(props);
producer.initTransactions();

producer.beginTransaction();
try {
    producer.send(new ProducerRecord<>("orders", key, orderJson));
    producer.send(new ProducerRecord<>("inventory", key, inventoryJson));
    producer.commitTransaction();
} catch (Exception e) {
    producer.abortTransaction(); // atomic rollback
}

// Consumer — read only committed messages
props.put("isolation.level", "read_committed");',
'EXPERT'),

-- ── Hibernate Questions ────────────────────────────────────────
((SELECT id FROM topics WHERE slug='hibernate'),
'What is the N+1 query problem and how do you fix it?',
'N+1 problem: 1 query fetches N parent records; then N separate queries fetch each child collection.
Result: 1 + N database round-trips instead of 1 or 2.

Cause: FetchType.LAZY (correct default) + accessing the collection inside a loop.

Fixes:
1. JOIN FETCH in JPQL — most common
2. @EntityGraph — declarative, avoids modifying repository
3. @BatchSize — lazy but batched (1 + ceil(N/batchSize) queries)
4. DTO projection — best for read-only, no entity overhead at all',
'// PROBLEM — triggers N+1
List<Department> depts = deptRepo.findAll(); // 1 query
depts.forEach(d -> d.getEmployees().size()); // N queries!

// FIX 1 — JOIN FETCH
@Query("SELECT d FROM Department d LEFT JOIN FETCH d.employees WHERE d.active = true")
List<Department> findAllWithEmployees();

// FIX 2 — @EntityGraph (no JPQL needed)
@EntityGraph(attributePaths = {"employees", "employees.address"})
List<Department> findByActiveTrue();

// FIX 3 — @BatchSize (good for deep graphs)
@OneToMany(fetch = FetchType.LAZY)
@BatchSize(size = 25)
private List<Employee> employees;
// Generates: SELECT * FROM employees WHERE dept_id IN (?,?,?,...25 ids)

// FIX 4 — DTO projection (read-only, zero entity overhead)
@Query("SELECT new com.example.DeptDto(d.name, COUNT(e)) FROM Department d JOIN d.employees e GROUP BY d.name")
List<DeptDto> findDeptSummaries();',
'HARD'),

-- ── System Design ──────────────────────────────────────────────
((SELECT id FROM topics WHERE slug='system-design'),
'How would you design a URL shortener like bit.ly?',
'Functional requirements: shorten URL, redirect short → long, analytics (click count)
Non-functional: 100M URLs, 1B reads/day, read:write = 10:1, low latency

Key components:
1. API: POST /shorten → returns short code; GET /{code} → 301 redirect
2. Short code: Base62 encode auto-increment ID → 7 chars = 62^7 = 3.5T unique codes
3. Database: (short_code PK, long_url, user_id, created_at, expires_at)
4. Cache: Redis for hot URLs. 20% URLs = 80% traffic (Pareto).
   Cache: GET short_code → long_url, TTL=1h
5. Redirect: 301 (permanent, browser caches) vs 302 (temporary, server counts each hit)
6. Scale: Read replicas, DB sharding by short_code hash, CDN for global edge',
'// Base62 encoding
private static final String CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

String encode(long id) {
    StringBuilder sb = new StringBuilder();
    while (id > 0) {
        sb.append(CHARS.charAt((int)(id % 62)));
        id /= 62;
    }
    return sb.reverse().toString(); // e.g. 12345678 → "5Fv3k2"
}

// Cache-aside for redirect
String getLongUrl(String shortCode) {
    String cached = redis.get("url:" + shortCode);
    if (cached != null) return cached;        // cache hit: ~1ms

    String longUrl = db.findByCode(shortCode); // cache miss: ~10ms
    redis.setex("url:" + shortCode, 3600, longUrl);
    return longUrl;
}

// Architecture:
// Client → CDN → Load Balancer → App Servers → Redis → PostgreSQL
// Write: App → DB → cache invalidation
// Read:  App → Redis (80% hit) → DB (20% miss)',
'EXPERT');

-- ── System Design Cases ────────────────────────────────────────
INSERT INTO system_design_cases (title, slug, description, requirements, scale, components, database_design, caching_strategy, diagram_mermaid) VALUES

('Design a URL Shortener', 'url-shortener',
'Build a URL shortening service like bit.ly with analytics',
'1. Shorten a long URL to a 7-char code
2. Redirect short URL to original
3. Track click count per short URL
4. Optional: user accounts, expiry dates',
'- 100M URLs stored
- 1B redirects/day (~11,500 req/sec reads)
- Read:Write = 10:1
- Availability: 99.9%',
'API Service, URL Encoder (Base62), PostgreSQL, Redis Cache, CDN',
'urls: (short_code PK, long_url, user_id FK, created_at, expires_at, click_count)
users: (id PK, email, created_at)',
'Cache short_code → long_url in Redis (TTL: 1h)
Pareto principle: 20% of URLs drive 80% of traffic
Cache hit rate target: ~85%',
'graph TD
    A[Client] --> B[CDN Edge]
    B -->|cache miss| C[Load Balancer]
    C --> D[App Servers]
    D -->|read| E[Redis Cache]
    E -->|miss| F[(PostgreSQL)]
    D -->|write| F'),

('Design Netflix', 'design-netflix',
'Video streaming platform serving 200M+ subscribers globally',
'1. Upload and transcode videos
2. Stream video adaptively (HLS/DASH)
3. Recommend content to users
4. Handle concurrent streaming globally',
'- 200M subscribers, 100M daily active
- 15% of global internet traffic
- Petabytes of video storage
- 1000+ microservices',
'CDN (Open Connect), Transcoding Pipeline, Recommendation Engine, API Gateway, Microservices',
'videos: (id, title, duration, status)
transcoded_files: (video_id, resolution, codec, s3_path)
user_watch_history: (user_id, video_id, watch_pct, watched_at)',
'CDN caches popular content at edge nodes globally
Redis caches: homepage recommendations (TTL: 1h), user session
Cassandra for watch history (write-heavy, append-only)',
'graph TD
    A[User] --> B[CDN Edge Server]
    B -->|video chunks| A
    C[Upload Service] --> D[Transcoding Queue]
    D --> E[Transcoding Workers]
    E --> F[(S3 Storage)]
    F --> B');
