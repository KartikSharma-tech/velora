# Velora Coding Rules

These rules must be followed throughout the project to maintain consistency, scalability, and clean architecture.

---

# General Rules

- Follow Clean Architecture.
- Follow Feature-First folder structure.
- Keep code readable.
- Prefer reusable components.
- Avoid duplicate code.
- Write meaningful variable and class names.

---

# UI Rules

- No Firebase calls inside Screens.
- No Firestore queries inside Widgets.
- UI should only display data.
- Keep widgets small.
- Extract reusable widgets.

---

# Riverpod Rules

- Riverpod is the only state management solution.
- Providers should not contain heavy business logic.
- Business logic belongs in Services, UseCases, or Sync Engines.

---

# Repository Rules

- Repository exposes interfaces.
- Repository Implementation handles data sources.
- Never access Firebase directly from Presentation.

---

# Data Source Rules

Remote Data Sources:

- Firebase Auth
- Firestore
- Firebase Messaging
- Firebase Realtime Database
- Cloudinary

Local Data Sources:

- Hive

---

# Model Rules

- One responsibility per model.
- Use immutable models where possible.
- Keep serialization inside models.

---

# Naming Convention

Classes:

PascalCase

Example:

UserRepository

ChatMessage

ProfileScreen

---

Variables:

camelCase

Example:

currentUser

chatRoomId

lastSeen

---

Files:

snake_case

Example:

chat_screen.dart

profile_repository.dart

contact_sync_engine.dart

---

Folder Naming

Use lowercase.

Example:

auth

chat

contacts

profile

---

Functions

Use descriptive names.

Examples:

sendMessage()

syncContacts()

uploadProfilePhoto()

createChatRequest()

---

Comments

Only comment complex logic.

Avoid obvious comments.

Good:

// Normalize phone number before Firestore lookup.

Bad:

// Increment i

---

Performance Rules

- Prefer const widgets.
- Minimize rebuilds.
- Cache data using Hive.
- Avoid unnecessary Firestore reads.
- Dispose controllers.
- Use pagination when needed.

---

Git Rules

- Small commits.
- Meaningful commit messages.
- Push daily.
- One feature per commit when possible.

---

Security Rules

- Never hardcode secrets.
- Never upload API keys or private credentials.
- Validate user input.
- Follow Firestore Security Rules.

---

Project Goal

Maintain a production-ready Flutter application that is scalable, maintainable, and interview-ready.