# Velora — Project Context

## Project Overview

Velora is a production-grade Flutter chat application built using Clean Architecture, Feature-First Architecture, and modern Flutter best practices.

The project aims to replicate the experience of modern messaging applications such as WhatsApp and Telegram while maintaining clean code, scalability, maintainability, offline support, and production-level architecture.

Velora is designed as an interview-quality portfolio project that demonstrates advanced Flutter development skills including architecture, state management, Firebase integration, local storage, performance optimization, and reusable UI components.

---

# Project Goals

- Build a production-ready Flutter application.
- Follow enterprise-level architecture.
- Write scalable and maintainable code.
- Keep business logic independent from UI.
- Support offline-first architecture.
- Follow SOLID Principles.
- Minimize technical debt.
- Maintain high code quality.
- Make the project easy to onboard for new developers.
- Keep AI assistants aware of the project architecture.

---

# Tech Stack

## Framework

- Flutter (Latest Stable)
- Dart 3

## State Management

- Riverpod

## Backend

- Firebase Authentication
- Cloud Firestore
- Firebase Realtime Database
- Firebase Cloud Messaging (FCM)
- Firebase Storage (if required)

## Local Database

- Hive

## Navigation

- GoRouter

## Media

- Cloudinary
- Image Picker
- Cached Network Image

## Networking

- Dio

## Utilities

- Flutter Secure Storage
- Connectivity Plus
- Logger
- UUID
- Intl

---

# Architecture

Velora follows Clean Architecture combined with Feature-First Architecture.

## Principles

- Clean Architecture
- Feature-First Structure
- Repository Pattern
- DataSource Pattern
- SOLID Principles
- Dependency Injection
- Riverpod State Management
- Separation of Concerns

---

# Folder Structure

```
lib/

├── app/
│   ├── router/
│   ├── theme/
│   └── bootstrap/

├── core/
│   ├── constants/
│   ├── services/
│   ├── utils/
│   ├── widgets/
│   ├── errors/
│   └── extensions/

├── features/

│   ├── auth/
│   ├── splash/
│   ├── home/
│   ├── chat/
│   ├── contacts/
│   ├── profile/
│   ├── settings/
│   ├── search/
│   └── notifications/

├── shared/

└── main.dart
```

---

# Layer Responsibilities

## Presentation Layer

Responsible for

- UI
- Screens
- Widgets
- Providers
- Navigation

Presentation Layer should NEVER contain business logic.

---

## Domain Layer

Responsible for

- Entities
- Repository Contracts
- UseCases

Domain Layer never depends on Firebase.

---

## Data Layer

Responsible for

- Models
- Repository Implementations
- Firebase APIs
- Hive APIs
- Remote Data Sources
- Local Data Sources

---

# State Management

Riverpod is the only state management solution used inside Velora.

Rules

- No setState for business logic.
- Providers should remain lightweight.
- AsyncNotifier preferred where applicable.
- No BuildContext inside Providers.
- Avoid Provider dependency cycles.

---

# Coding Rules

## UI

- No Firebase code inside Screens.
- No business logic inside Widgets.
- Widgets should be reusable.
- Prefer StatelessWidget.
- Keep widgets under 250 lines.
- Use const constructors whenever possible.

---

## Business Logic

- Business logic belongs inside Services or UseCases.
- Repository Pattern must always be followed.
- Never duplicate logic.
- Prefer composition over inheritance.
- Async/Await preferred.
- Handle all exceptions properly.

---

## Firebase Rules

Allowed only inside

- Repository
- Data Source
- Service Layer

Never inside

- Screens
- Widgets
- UI Components

---

## Hive Rules

- All local caching handled through Hive.
- Hive models remain independent.
- No direct Hive usage inside UI.

---

# Naming Conventions

Classes

```
ChatRepository
ProfileProvider
MessageModel
```

Screens

```
HomeScreen
ChatScreen
SettingsScreen
```

Providers

```
chatProvider
profileProvider
authProvider
```

Repositories

```
ChatRepository
ChatRepositoryImpl
```

Services

```
CloudinaryService
NotificationService
StorageService
```

---

# Current Features

## Authentication

✅ Email Login

✅ Signup

✅ Forgot Password

✅ Splash Flow

---

## Chat

✅ One-to-One Chat

✅ Real-time Messaging

✅ Typing Indicator

✅ Delete for Me

✅ Delete for Everyone

✅ Message Reactions

✅ Pin Chat

---

## User

✅ Username Search

✅ Profile

✅ Profile Picture Upload

✅ Contact Sync

---

## Storage

✅ Hive Offline Cache

---

## Settings

✅ Settings Screen

---

# Current Sprint

Current development priority

- Phone Number Authentication
- Image Sharing
- Push Notifications
- Chat Media Improvements

---

# Pending Features

## High Priority

- Phone Number Login
- Push Notifications
- Image Sharing

---

## Medium Priority

- Archive Chats
- Chat Wallpaper
- Invite Friends
- Email Verification

---

## Future Features

- Voice Notes
- Group Chat
- Status / Stories
- Message Forward
- Video Messages
- Calls
- End-to-End Encryption

---

# Performance Rules

- Lazy load images.
- Cache frequently used data.
- Avoid unnecessary rebuilds.
- Use const widgets.
- Minimize widget tree depth.
- Dispose controllers properly.
- Keep Provider scope optimized.

---

# Error Handling

Every Repository must return

- Success
- Failure

Never throw raw exceptions to UI.

Use

- try/catch
- Custom Exceptions
- Failure Models

---

# Git Strategy

Main Branches

```
main
develop
```

Feature Branches

```
feature/auth
feature/chat
feature/profile
```

Bug Fixes

```
bugfix/login
bugfix/image-upload
```

Hotfix

```
hotfix/firebase-crash
```

---

# Commit Message Style

Examples

```
feat(auth): add phone authentication

feat(chat): implement message reactions

fix(profile): resolve image upload issue

refactor(chat): simplify repository

docs(project): update project context
```

---

# Documentation Rules

Every public service should include

- Purpose
- Parameters
- Returns

Complex logic should include concise comments.

Avoid unnecessary comments.

---

# Security Rules

- Never expose Firebase keys inside code comments.
- Never commit secrets.
- Validate user inputs.
- Sanitize uploaded data.
- Apply Firestore Security Rules.
- Follow least privilege principle.

---

# Testing Strategy

Future

- Unit Testing
- Repository Testing
- Widget Testing
- Integration Testing

---

# AI Assistant Guidelines

This repository is frequently used with AI coding assistants.

Important rules

- Never move business logic into UI.
- Respect Clean Architecture.
- Maintain Feature-First structure.
- Prefer reusable components.
- Avoid duplicate implementations.
- Keep existing architecture intact.
- Do not introduce breaking architectural changes without strong justification.

---

# Long-Term Vision

Velora is intended to become an enterprise-quality Flutter chat application showcasing modern architecture, scalable development practices, offline support, real-time communication, maintainable code, and production-level engineering standards.

The project should remain interview-ready, portfolio-worthy, and easily extensible for future features while maintaining high code quality.