import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat_requests/data/models/chat_request_model.dart';
import '../../../chat_requests/presentation/providers/chat_request_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../user/data/models/user_model.dart';
import '../../domain/services/messaging_permission.dart';
import '../providers/chat_provider.dart';

/// Gathers the three signals `MessagingPermissionEvaluator` needs
/// (existing room / contact match / accepted request) and resolves
/// whether [currentUserId] can message [target] directly, needs to
/// send a Chat Request first, or is blocked outright.
class MessagingPermissionResolver {
  const MessagingPermissionResolver._();

  static Future<MessagingPermission> resolve({
    required WidgetRef ref,
    required String currentUserId,
    required UserModel target,
  }) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final requestRepo = ref.read(chatRequestRepositoryProvider);

    final roomExists = await chatRepo.chatRoomExists([currentUserId, target.uid]);

    if (roomExists) {
      return MessagingPermission.allowed;
    }

    // "Is the target one of *my* matched contacts" — reuses
    // whatever this session already fetched via the Discover
    // screen; if it hasn't loaded yet, this awaits the same
    // future rather than re-reading the device address book.
    final matchedContacts =
        await ref.read(matchedContactsProvider(currentUserId).future);
    final senderIsTargetsContact =
        matchedContacts.any((c) => c.user.uid == target.uid);

    final existingRequest = await requestRepo.getRequestBetween(
      fromUserId: currentUserId,
      toUserId: target.uid,
    );
    final hasAcceptedRequest =
        existingRequest?.status == ChatRequestStatus.accepted;

    return MessagingPermissionEvaluator.evaluate(
      targetWhoCanMessage: target.whoCanMessage,
      chatRoomAlreadyExists: roomExists,
      senderIsTargetsContact: senderIsTargetsContact,
      hasAcceptedRequest: hasAcceptedRequest,
    );
  }
}
