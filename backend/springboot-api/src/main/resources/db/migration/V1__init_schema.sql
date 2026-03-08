-- ================================================================
-- V1__init_schema.sql
-- Aryan JIP Assistant — Initial Database Schema
-- ================================================================

-- ── Users ──────────────────────────────────────────────────────
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username    VARCHAR(50)  UNIQUE NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    password    VARCHAR(255) NOT NULL,
    role        VARCHAR(20)  NOT NULL DEFAULT 'USER'
                CHECK (role IN ('USER', 'ADMIN')),
    first_name  VARCHAR(60),
    last_name   VARCHAR(60),
    is_active   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email    ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- ── Topics (Java, Spring Boot, Kafka etc.) ─────────────────────
CREATE TABLE topics (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(100) NOT NULL,
    slug        VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon        VARCHAR(50),
    order_index INTEGER DEFAULT 0,
    is_active   BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_topics_slug ON topics(slug);

-- ── Questions ──────────────────────────────────────────────────
CREATE TABLE questions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id         UUID NOT NULL REFERENCES topics(id),
    question_text    TEXT NOT NULL,
    answer_text      TEXT NOT NULL,
    code_example     TEXT,
    difficulty       VARCHAR(20) NOT NULL DEFAULT 'MEDIUM'
                     CHECK (difficulty IN ('EASY','MEDIUM','HARD','EXPERT')),
    is_quiz_eligible BOOLEAN DEFAULT TRUE,
    view_count       INTEGER DEFAULT 0,
    created_at       TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_questions_topic      ON questions(topic_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);

-- ── Quiz Sessions ──────────────────────────────────────────────
CREATE TABLE quiz_sessions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id),
    topic_slug       VARCHAR(100) NOT NULL,
    total_questions  INTEGER NOT NULL,
    correct_answers  INTEGER DEFAULT 0,
    score            INTEGER DEFAULT 0,
    is_completed     BOOLEAN DEFAULT FALSE,
    question_ids     TEXT,     -- JSON array of question UUIDs
    started_at       TIMESTAMP DEFAULT NOW(),
    completed_at     TIMESTAMP
);

CREATE INDEX idx_quiz_sessions_user ON quiz_sessions(user_id);

-- ── Quiz Answers ───────────────────────────────────────────────
CREATE TABLE quiz_answers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES quiz_sessions(id),
    question_id     UUID NOT NULL REFERENCES questions(id),
    selected_answer TEXT NOT NULL,
    is_correct      BOOLEAN NOT NULL
);

CREATE INDEX idx_quiz_answers_session ON quiz_answers(session_id);

-- ── User Progress per Topic ────────────────────────────────────
CREATE TABLE user_progress (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id),
    topic_slug          VARCHAR(100) NOT NULL,
    quizzes_taken       INTEGER DEFAULT 0,
    best_score          INTEGER DEFAULT 0,
    mastery_pct         INTEGER DEFAULT 0,
    last_activity       TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uq_user_topic UNIQUE (user_id, topic_slug)
);

CREATE INDEX idx_user_progress_user ON user_progress(user_id);

-- ── System Design Case Studies ─────────────────────────────────
CREATE TABLE system_design_cases (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(200) NOT NULL,
    slug            VARCHAR(200) UNIQUE NOT NULL,
    description     TEXT,
    requirements    TEXT,    -- functional requirements
    scale           TEXT,    -- scale assumptions
    components      TEXT,    -- key system components
    database_design TEXT,    -- DB schema decisions
    caching_strategy TEXT,   -- Redis / CDN strategy
    diagram_mermaid TEXT,    -- Mermaid.js diagram code
    is_published    BOOLEAN DEFAULT TRUE
);
