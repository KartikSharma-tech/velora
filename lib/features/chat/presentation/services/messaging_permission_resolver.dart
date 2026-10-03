import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../chat_requests/data/models/chat_request_model.dart';
import '../../../chat_requests/presentation/providers/chat_request_provider.dart';
import '../../../contacts/presentation/providers/contacts_provider.dart';
import '../../../user/data/models/user_model.dart';
import '../../domain/services/messaging_permission.dart';
import '../providers/chat_provider.dart';

class MessagingPermissionResolver {
  const MessagingPermissionResolver._();

  static Future<MessagingPermission> resolve({
    required WidgetRef ref,
    required String currentUserId,
    required UserModel target,
  }) async {
    if (currentUserId.isEmpty || target.uid.isEmpty) {
      return MessagingPermission.blocked;
    }

    final chatRepo = ref.read(chatRepositoryProvider);
    final requestRepo = ref.read(chatRequestRepositoryProvider);

    final roomExists = await chatRepo.chatRoomExists([currentUserId, target.uid]);

    if (roomExists) {
      return MessagingPermission.allowed;
    }

    final syncState = ref.read(contactSyncProvider(false));

    final senderIsTargetsContact = switch (syncState) {
      AsyncData(:final value) => value.onVelora.any((c) => c.uid == target.uid),
      AsyncLoading() => false,
      AsyncError() => false,
      _ => false,
    };

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