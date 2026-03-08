# 🎓 Aryan-JIP-Assistant
### Java Interview Preparation Platform — Senior Engineer Edition

[![Java](https://img.shields.io/badge/Java-21-orange?style=flat-square&logo=openjdk)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2-brightgreen?style=flat-square&logo=springboot)](https://spring.io/projects/spring-boot)
[![Next.js](https://img.shields.io/badge/Next.js-14-black?style=flat-square&logo=next.js)](https://nextjs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue?style=flat-square&logo=postgresql)](https://postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-red?style=flat-square&logo=redis)](https://redis.io/)
[![Kafka](https://img.shields.io/badge/Kafka-3.6-black?style=flat-square&logo=apache-kafka)](https://kafka.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue?style=flat-square&logo=docker)](https://docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 🎯 What Is This?

**Aryan-JIP-Assistant** is a portfolio-quality interview preparation platform built for experienced Java developers targeting **Senior Engineer**, **Staff Engineer**, and **Software Architect** roles.

It runs entirely **locally using Docker Compose** — no AWS account, no Terraform, no cloud costs.

> Built to demonstrate: modular monolith architecture, event-driven design with Kafka, Redis caching, JWT security, and clean code practices expected from a 10+ year Java developer.

---

## 🏛️ Architecture

```
┌─────────────────────────────────────────────────────┐
│              Next.js Frontend (:3000)               │
│         React + TailwindCSS + TypeScript            │
└──────────────────────┬──────────────────────────────┘
                       │ REST API
┌──────────────────────▼──────────────────────────────┐
│          Spring Boot Modular Monolith (:8080)       │
│  ┌──────────┬──────────┬──────────┬──────────────┐  │
│  │  User    │ Content  │  Quiz    │System Design │  │
│  │ Module   │ Module   │ Module   │   Module     │  │
│  └────┬─────┴────┬─────┴────┬─────┴──────────────┘  │
│       │          │          │  Kafka Events          │
│  ┌────▼──────────▼──────────▼──────────────────┐    │
│  │            Analytics Module                  │    │
│  └──────────────────────────────────────────────┘    │
└──────────┬──────────────┬─────────────┬──────────────┘
           │              │             │
    ┌──────▼──┐    ┌──────▼──┐   ┌─────▼──────┐
    │Postgres │    │  Redis  │   │   Kafka    │
    │  (:5432)│    │  (:6379)│   │   (:9092)  │
    └─────────┘    └─────────┘   └────────────┘
```

---

## 📚 Topics Covered

| Topic | Questions | Type |
|-------|-----------|------|
| ☕ Java 21 | 80+ | Core + Advanced |
| 🌱 Spring Boot | 60+ | Architecture + Practice |
| 🗄️ Hibernate/JPA | 50+ | ORM Deep Dive |
| 🔐 Spring Security | 40+ | JWT + OAuth2 |
| 🗃️ SQL & Databases | 60+ | Design + Optimization |
| 🏗️ Microservices | 45+ | Patterns + Design |
| 📨 Apache Kafka | 35+ | Messaging + Streaming |
| 📐 System Design | 20+ | Case Studies |
| ☁️ AWS Concepts | 40+ | Architecture |
| ⚛️ React JS | 35+ | Modern Frontend |

---

## 🛠️ Tech Stack

```
Backend  │ Java 21 · Spring Boot 3.2 · Spring Security · Hibernate/JPA · Gradle
Database │ PostgreSQL 15 · Flyway (migrations)
Cache    │ Redis 7 (Cache-Aside pattern)
Messaging│ Apache Kafka 3.6 (event-driven analytics)
Frontend │ Next.js 14 · React 18 · TypeScript · TailwindCSS
Infra    │ Docker · Docker Compose (runs 100% locally)
```

---

## 🚀 Quick Start

### One-Command Setup
```bash
git clone https://github.com/yourname/aryan-jip-assistant.git
cd aryan-jip-assistant
docker-compose up --build
```

Open http://localhost:3000

That's it. All services start automatically.

### Service URLs
| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8080 |
| API Docs (Swagger) | http://localhost:8080/swagger-ui.html |
| Kafka UI | http://localhost:8090 |

### Default Credentials
| Role | Username | Password |
|------|----------|----------|
| Admin | admin@jip.dev | admin123 |
| User | user@jip.dev | user123 |

---

## 📁 Project Structure

```
aryan-jip-assistant/
│
├── frontend/
│   └── nextjs-ui/
│       ├── src/
│       │   ├── app/                  # Next.js 14 App Router
│       │   │   ├── (auth)/           # Login, Register
│       │   │   ├── dashboard/        # Main learning dashboard
│       │   │   ├── topics/[slug]/    # Each interview topic
│       │   │   ├── quiz/             # Quiz engine
│       │   │   └── system-design/    # Case studies
│       │   ├── components/           # Reusable UI components
│       │   ├── hooks/                # Custom React hooks
│       │   └── lib/                  # API client, utilities
│       └── package.json
│
├── backend/
│   └── springboot-api/
│       └── src/main/java/com/aryan/jip/
│           ├── user/                 # Auth + JWT + Progress
│           ├── content/              # Questions + Topics
│           ├── quiz/                 # Quiz engine
│           ├── systemdesign/         # Case studies
│           ├── analytics/            # Kafka consumer + stats
│           └── common/               # Config + Security + Utils
│
├── infrastructure/
│   └── docker-compose.yml
│
└── docs/
    ├── architecture.md
    └── api.md
```

---

## 🔌 API Overview

### Auth
```
POST /api/auth/register    Register new user
POST /api/auth/login       Login → JWT token
GET  /api/auth/me          Current user profile
```

### Content
```
GET  /api/topics           All topics with question counts
GET  /api/topics/{slug}    Topic detail + questions
GET  /api/questions/{id}   Single question with explanation
```

### Quiz
```
POST /api/quiz/start       Start quiz for a topic
POST /api/quiz/submit      Submit answers → score
GET  /api/quiz/history     User's quiz history
```

### Analytics
```
GET  /api/analytics/dashboard   User's learning stats
GET  /api/analytics/progress    Topic-by-topic progress
```

---

## 📊 Database Schema

```sql
users               -- registered users + roles
topics              -- java, spring, kafka etc.
questions           -- interview questions per topic
quiz_sessions       -- quiz attempts
quiz_answers        -- per-question answers
user_progress       -- topic mastery % per user
system_design_cases -- URL shortener, Netflix etc.
```

---

## ⚡ Kafka Events

```
Quiz completed  →  quiz-events topic  →  Analytics Module
                                         (updates mastery %)

Progress update →  progress-events   →  Analytics Module
                                         (leaderboard refresh)
```

---

## 🔒 Security

- JWT tokens (access: 1h, refresh: 7d)
- BCrypt password encoding
- Role-based: USER / ADMIN
- CORS configured for localhost:3000

---

## 🧪 Running Tests

```bash
cd backend/springboot-api
./gradlew test

# With coverage report
./gradlew test jacocoTestReport
```

---

## 📄 License

MIT — built as a portfolio project by **Aryan Agrawal**

---

*10+ years of Java engineering, distilled into one clean project. ⭐ Star if this helped your interview prep!*
