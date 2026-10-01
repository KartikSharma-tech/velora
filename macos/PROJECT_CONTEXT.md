# Velora — Project Context

## Project

Velora is a production-ready Flutter chat application built with Clean Architecture and Feature-First architecture.

The goal is to create an interview-level, scalable, and maintainable chat application similar to WhatsApp while following modern Flutter development practices.

---

# Tech Stack

- Flutter
- Dart
- Riverpod
- Firebase Authentication
- Cloud Firestore
- Firebase Messaging (FCM)
- Firebase Realtime Database (Presence)
- Hive
- GoRouter
- Cloudinary
- Image Picker

---

# Architecture

- Clean Architecture
- Feature-First Structure
- Repository Pattern
- SOLID Principles
- Dependency Injection
- Riverpod State Management

---

# Project Rules

- No business logic inside UI.
- No direct Firebase calls from Screens.
- Repository Pattern must be followed.
- Every feature should follow Clean Architecture.
- Business logic belongs inside Services / Sync Engines / UseCases.
- Riverpod is the only state management solution.
- Keep files small and reusable.
- Prefer composition over duplication.

---

# Folder Structure

lib/

app/

core/

features/

shared/

main.dart

---

# Current Status

## Completed

- Authentication
- Splash
- Login
- Signup
- Forgot Password Screen
- Home Screen
- One-to-One Chat
- Username Search
- Chat Requests
- Typing Indicator
- Delete Messages
- Message Reactions
- Profile
- Cloudinary Profile Upload
- Contact Sync
- Hive Offline Cache

---

# Current Feature

Phone Number Signup

---

# Pending Features

- Phone Number Signup
- Email Verification
- Invite Friends
- Push Notifications
- Image Sharing
- Archive Chats
- Chat Wallpaper
- Voice Notes
- Group Chat

---

# Coding Style

- Use meaningful class names.
- Keep widgets reusable.
- Avoid duplicate code.
- Follow feature-first structure.
- Prefer async/await.
- Keep UI separated from logic.

---

# Git Strategy

Feature Branches

Meaningful Commit Messages

Small Commits

Daily Push

---

# Goal

Build a production-ready Flutter chat application that is suitable for portfolio, interviews, and real-world scalability.