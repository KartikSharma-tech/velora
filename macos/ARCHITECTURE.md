# Velora Architecture

## Overview

Velora follows a Feature-First Clean Architecture.

The goal is to separate UI, Business Logic, and Data Layer to keep the project scalable, testable, and maintainable.

---

# High Level Architecture

Presentation
↓
Provider (Riverpod)
↓
UseCase / Service / Sync Engine
↓
Repository (Abstract)
↓
Repository Implementation
↓
Local / Remote Data Sources
↓
Hive / Firebase / Cloudinary

---

# Layer Responsibilities

## Presentation

Responsible for:

- Screens
- Widgets
- User Interaction
- Navigation

Rules:

- No Firebase calls
- No Firestore queries
- No business logic

---

## Providers

Responsible for:

- State Management
- Calling UseCases
- Managing UI State

Rules:

- Keep providers lightweight.
- Business logic belongs elsewhere.

---

## UseCases / Services / Sync Engines

Responsible for:

- Business Logic
- Validation
- Feature Workflow
- Synchronization

Examples:

- ContactSyncEngine
- AuthService
- ChatService

---

## Repository

Responsible for:

- Defining interfaces.
- Hiding implementation details.

Rules:

- No UI code.
- No widget references.

---

## Repository Implementation

Responsible for:

Connecting repositories with data sources.

---

## Data Sources

### Remote

- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Firebase Realtime Database
- Cloudinary

### Local

- Hive

---

# Feature Structure

features/

auth/

chat/

contacts/

home/

profile/

settings/

splash/

Each feature contains:

- data/
- domain/
- presentation/

---

# Data Flow

User taps button

↓

Provider

↓

UseCase / Sync Engine

↓

Repository

↓

Datasource

↓

Firebase / Hive

↓

Repository

↓

Provider

↓

UI Updates

---

# Design Principles

- Clean Architecture
- SOLID Principles
- Repository Pattern
- Feature-First
- Riverpod
- Dependency Injection
- Reusable Widgets
- Separation of Concerns

---

# Performance Rules

- Minimize Firestore reads.
- Use Hive cache whenever possible.
- Keep widgets const where possible.
- Avoid rebuilding unnecessary widgets.
- Use Streams only when required.

---

# Security Rules

- Never expose secrets.
- Never call Firebase directly from UI.
- Validate user input.
- Use Firestore Security Rules.
- Respect user privacy settings.

---

# Future Scalability

Architecture supports:

- Group Chats
- Voice Messages
- Video Calls
- Communities
- Status
- Offline Mode
- Background Sync
- Multi-device Support
