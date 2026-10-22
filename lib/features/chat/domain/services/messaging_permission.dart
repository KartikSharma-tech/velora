import '../../../../shared/enums/privacy_enums.dart';

enum MessagingPermission {
  /// Direct chat is allowed — open/create the chat room as normal.
  allowed,

  /// No accepted request yet, but the target allows requests.
  requestRequired,

  /// The target's settings don't allow this sender to reach them
  /// at all (`nobody`, or `contacts`-only and they're not a
  /// contact) — no request option either.
  blocked,
}

/// Pure evaluation of Settings → Privacy → "Who can message me"
/// against a specific sender/target pair. No I/O — callers gather
/// existing-room and accepted-request state from their repositories first.
class MessagingPermissionEvaluator {
  const MessagingPermissionEvaluator._();

  static MessagingPermission evaluate({
    required WhoCanMessage targetWhoCanMessage,
    required bool chatRoomAlreadyExists,
    required bool recipientHasSenderAsContact,
    required bool hasAcceptedRequest,
  }) {
    // Grandfather existing conversations — tightening your privacy
    // settings shouldn't retroactively cut off someone you're
    // already talking to.
    if (chatRoomAlreadyExists) return MessagingPermission.allowed;

    switch (targetWhoCanMessage) {
      case WhoCanMessage.anyone:
        return MessagingPermission.allowed;

      case WhoCanMessage.contacts:
        return recipientHasSenderAsContact
            ? MessagingPermission.allowed
            : MessagingPermission.blocked;

      case WhoCanMessage.contactsAndRequests:
        if (recipientHasSenderAsContact || hasAcceptedRequest) {
          return MessagingPermission.allowed;
        }
        return MessagingPermission.requestRequired;

      case WhoCanMessage.nobody:
        return MessagingPermission.blocked;
    }
  }
}
