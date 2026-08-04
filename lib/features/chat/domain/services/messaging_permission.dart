import '../../../../shared/enums/privacy_enums.dart';

enum MessagingPermission {
  /// Direct chat is allowed — open/create the chat room as normal.
  allowed,

  /// Not a contact / no accepted request yet, but the target's
  /// `whoCanMessage` is `contactsAndRequests`, so a Chat Request
  /// can be sent to unlock messaging.
  requestRequired,

  /// The target's settings don't allow this sender to reach them
  /// at all (`nobody`, or `contacts`-only and they're not a
  /// contact) — no request option either.
  blocked,
}

/// Pure evaluation of Settings → Privacy → "Who can message me"
/// against a specific sender/target pair. No I/O — callers gather
/// the three booleans (existing room, contact match, accepted
/// request) from their respective repositories first.
class MessagingPermissionEvaluator {
  const MessagingPermissionEvaluator._();

  static MessagingPermission evaluate({
    required WhoCanMessage targetWhoCanMessage,
    required bool chatRoomAlreadyExists,
    required bool senderIsTargetsContact,
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
        return senderIsTargetsContact
            ? MessagingPermission.allowed
            : MessagingPermission.blocked;

      case WhoCanMessage.contactsAndRequests:
        if (senderIsTargetsContact || hasAcceptedRequest) {
          return MessagingPermission.allowed;
        }
        return MessagingPermission.requestRequired;

      case WhoCanMessage.nobody:
        return MessagingPermission.blocked;
    }
  }
}
