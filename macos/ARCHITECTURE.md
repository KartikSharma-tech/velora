# Velora — Architecture

Last Updated: 2026-10-06

---

# Overview

Velora is a production-ready Flutter chat application built using:

- Clean Architecture
- Feature-First Architecture
- Repository Pattern
- SOLID Principles
- Riverpod
- Dependency Injection
- Offline-First Design

The architecture separates Presentation, Business Logic, and Data layers to maximize scalability, maintainability, testability, and long-term growth.

---

# Technology Stack

Frontend

- Flutter
- Dart

State Management

- Riverpod

Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Realtime Database

Local Storage

- Hive

Media

- Cloudinary

Navigation

- GoRouter

---

# High-Level Architecture

```
                 UI
                 │
                 ▼
      Presentation Layer
                 │
                 ▼
      Riverpod Providers
                 │
                 ▼
     UseCases / Services
     Sync Engines / Resolver
                 │
                 ▼
 Repository (Abstract Interface)
                 │
                 ▼
 Repository Implementation
          │             │
          ▼             ▼
 Local Data       Remote Data
    Hive          Firebase
                    │
                    ▼
          Firestore / Auth /
         Realtime DB / FCM /
           Cloudinary
```

---

# Layer Responsibilities

## Presentation Layer

Contains

- Screens
- Widgets
- Navigation
- UI State

Responsibilities

- Display data
- Handle user interactions
- Listen to Providers

Never

- Call Firebase
- Query Firestore
- Write business logic

---

## Provider Layer

Riverpod Providers

Responsibilities

- Expose state
- Call repositories
- Trigger use cases

Rules

- Lightweight
- No business logic
- No Firestore queries

---

## Domain Layer

Contains

- Entities
- Repository Interfaces
- UseCases

Business Logic

- Validation
- Decision Making
- Workflow

Examples

- ContactSyncEngine
- MessagingPermissionResolver
- PhoneNormalizer

---

## Repository Layer

Responsibilities

- Hide implementation
- Expose clean interfaces

Presentation communicates only with Repository interfaces.

---

## Repository Implementation

Responsibilities

- Combine Local + Remote Data
- Cache Management
- Synchronization
- Data Transformation

---

## Data Sources

### Remote

- Firebase Authentication
- Cloud Firestore
- Firebase Realtime Database
- Firebase Cloud Messaging
- Cloudinary

### Local

- Hive

Rules

Only CRUD operations.

No business logic.

---

# Feature Structure

```
features/

auth/
chat/
chat_requests/
contacts/
home/
profile/
search/
notifications/
settings/
splash/
stories/
calls/
groups/
communities/
```

Each feature follows

```
feature/

data/
    datasources/
    models/
    repositories/

domain/
    entities/
    repositories/
    usecases/

presentation/
    providers/
    screens/
    widgets/
```

---

# Data Flow

```
User

↓

Screen

↓

Riverpod Provider

↓

UseCase / Service

↓

Repository Interface

↓

Repository Implementation

↓

Remote / Local Datasource

↓

Firebase / Hive

↓

Repository

↓

Provider

↓

UI Update
```

---

# Messaging Flow

### Contact Available

```
Device Contacts

↓

Contact Sync

↓

Firestore Matching

↓

Matched Contact

↓

Direct Chat
```

---

### Unknown User

```
Search Username

↓

Send Chat Request

↓

Accept

↓

Create Chat Room

↓

Messaging Enabled
```

Rejected request

↓

No messaging access

---

# Offline Strategy

Hive stores

- User
- Contacts
- Settings
- Cached Chats
- Preferences

Firestore remains source of truth.

Future

- Offline Messaging Queue
- Background Synchronization

---

# Dependency Rules

Allowed

```
Presentation
      ↓
Domain
      ↓
Repository
      ↓
Datasource
```

Forbidden

❌ UI → Firebase

❌ UI → Firestore

❌ Widget → Hive

❌ Screen → Cloudinary

❌ Provider → Firestore

---

# Performance Strategy

- Prefer const widgets
- Cache contacts
- Cache user profile
- Minimize Firestore reads
- Lazy loading
- Pagination
- Stream only required collections
- Reuse widgets
- Dispose controllers

---

# Security Architecture

Authentication

- Firebase Authentication

Authorization

- Firestore Security Rules

Storage

- Hive (non-sensitive)
- flutter_secure_storage (planned)

Validation

- Input Validation
- Phone Number Normalization

Future

- Firebase App Check
- End-to-End Encryption
- Secure Storage
- Certificate Pinning

---

# Design Principles

- Clean Architecture
- SOLID Principles
- Repository Pattern
- Feature-First
- Separation of Concerns
- Composition over Inheritance
- Dependency Injection
- Reusable Widgets

---

# Scalability

Current architecture supports future implementation of

- Group Chat
- Communities
- Voice Messages
- Video Sharing
- Voice Calling
- Video Calling
- Stories
- Chat Search
- Chat Backup
- Multi-device Support
- End-to-End Encryption
- AI Features

without requiring major architectural changes.

---

# Project Goal

Velora is designed to be a production-ready Flutter application demonstrating modern mobile engineering practices, scalable architecture, and enterprise-level code organization suitable for real-world deployment and technical interviews.