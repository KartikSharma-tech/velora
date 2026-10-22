import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/messaging_permission.dart';
import '../../../user/data/models/user_model.dart';
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
    return ref
        .read(messagingPermissionDataSourceProvider)
        .resolve(currentUserId: currentUserId, targetUserId: target.uid);
  }
}
