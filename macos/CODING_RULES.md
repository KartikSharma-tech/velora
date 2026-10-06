# Velora — Coding Rules

These rules are mandatory for every contributor and AI coding assistant working on the Velora project.

The primary goals are:

- Maintainability
- Scalability
- Performance
- Security
- Readability
- Clean Architecture
- Production Readiness

---

# 1. Architecture Rules

Velora strictly follows:

- Clean Architecture
- Feature-First Structure
- Repository Pattern
- DataSource Pattern
- SOLID Principles
- Separation of Concerns
- Dependency Injection
- Riverpod State Management

Never violate architecture for convenience.

---

# 2. Folder Rules

Every feature must follow:

```
feature/

data/
domain/
presentation/
```

Inside presentation

```
providers/
screens/
widgets/
```

Inside data

```
datasources/
models/
repositories/
```

Inside domain

```
entities/
repositories/
usecases/
```

No exceptions.

---

# 3. UI Rules

UI should only display data.

Never

- Call Firebase
- Query Firestore
- Access Hive
- Perform business logic

UI responsibilities

- Render widgets
- Call Providers
- Show Loading
- Show Errors
- Navigate

Keep widgets reusable.

Extract widgets larger than 250 lines.

Prefer StatelessWidget.

Use const constructors whenever possible.

---

# 4. Riverpod Rules

Riverpod is the only state management solution.

Rules

- Keep Providers lightweight.
- No heavy business logic.
- No BuildContext inside Providers.
- Providers should communicate with Repositories only.
- Avoid circular dependencies.

---

# 5. Repository Rules

Repositories expose abstract interfaces.

Repository Implementation handles

- Firebase
- Hive
- Cloudinary
- APIs

Presentation layer must never import Firebase packages.

---

# 6. Data Source Rules

Remote Data Sources

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Messaging
- Firebase Realtime Database
- Cloudinary

Local Data Sources

- Hive

DataSources should perform CRUD only.

Business logic never belongs here.

---

# 7. Model Rules

Every model has one responsibility.

Rules

- Immutable where possible.
- Serialization inside Model.
- fromMap()
- toMap()
- copyWith()
- Equality support.

Avoid unnecessary fields.

---

# 8. Naming Conventions

## Classes

PascalCase

Examples

```
ChatRepository
MessageModel
ProfileProvider
```

---

## Variables

camelCase

Examples

```
currentUser
chatRoomId
lastSeen
messageCount
```

---

## Files

snake_case

Examples

```
chat_screen.dart
message_model.dart
auth_repository.dart
```

---

## Folders

Lowercase only.

Examples

```
chat
profile
contacts
settings
```

---

## Functions

Function names should describe actions.

Examples

```
sendMessage()
syncContacts()
uploadProfilePhoto()
createChatRoom()
deleteMessage()
toggleReaction()
```

---

# 9. Widget Rules

Maximum widget size

250 lines

Maximum screen size

400 lines

If exceeded

Split into

- Widgets
- Components
- Sections

---

# 10. Performance Rules

Always

- Use const widgets.
- Cache expensive operations.
- Cache Firestore results.
- Minimize rebuilds.
- Use lazy loading.
- Dispose controllers.
- Use pagination.
- Optimize ListView.

Avoid

- Nested FutureBuilders
- Nested StreamBuilders
- Unnecessary rebuilds

---

# 11. Firestore Rules

Never

- Read entire collections.
- Fetch unnecessary fields.
- Duplicate queries.

Always

- Use indexes.
- Use pagination.
- Filter on server.
- Keep documents small.

---

# 12. Hive Rules

Hive stores

- Cached User
- Contacts
- Settings
- Offline Data

Never store

- Passwords
- Firebase Tokens
- Sensitive Secrets

---

# 13. Security Rules

Never

- Hardcode secrets.
- Commit service accounts.
- Commit private keys.
- Store passwords locally.
- Disable Firestore Rules.

Always

- Validate user input.
- Sanitize data.
- Use Firestore Security Rules.
- Use Firebase Authentication.
- Use flutter_secure_storage for sensitive tokens.
- Enable Firebase App Check before production.

---

# 14. Error Handling Rules

Never ignore exceptions.

Always

```
try
catch
finally
```

Convert exceptions into Failure models.

UI should never receive raw exceptions.

---

# 15. Logging Rules

Use Logger Service only.

Never log

- Passwords
- Tokens
- OTPs
- Email verification links
- API Secrets

Remove debug logs before production.

---

# 16. Git Rules

Branch naming

```
feature/chat

feature/profile

bugfix/login

hotfix/firestore

refactor/chat
```

Commit Rules

Small commits.

One feature per commit.

Examples

```
feat(chat): add contact based messaging

feat(profile): add profile image upload

fix(chat): resolve Firestore permission issue

refactor(chat): simplify repository layer

docs: update feature status
```

Push daily.

---

# 17. Documentation Rules

Every feature should include

- Purpose
- Architecture
- Dependencies

Complex methods should have concise documentation.

Avoid unnecessary comments.

---

# 18. Testing Rules

Future requirement

- Unit Tests
- Widget Tests
- Integration Tests

Critical features must eventually be covered.

---

# 19. AI Assistant Rules

AI-generated code must

- Follow Clean Architecture.
- Respect Feature-First Structure.
- Avoid duplicate code.
- Keep business logic outside UI.
- Preserve existing architecture.
- Prefer reusable widgets.
- Follow repository pattern.
- Never introduce architectural shortcuts.

---

# 20. Code Review Checklist

Before every commit verify

- Architecture maintained
- No duplicated code
- No Firebase in UI
- No business logic in widgets
- Proper error handling
- No debug code
- No unnecessary prints
- Proper naming
- Const widgets used
- Security rules respected
- Formatting completed
- Analyzer warnings resolved

---

# Project Standard

Velora should always remain

- Production Ready
- Scalable
- Secure
- Maintainable
- Performant
- Interview Ready
- Enterprise Quality

Every new feature must comply with these rules before merging into the main branch.