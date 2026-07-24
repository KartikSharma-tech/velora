import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_chat_datasource.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';

/// ===========================================================
/// Firestore Chat DataSource
/// ===========================================================

final firestoreChatDataSourceProvider =
    Provider<FirestoreChatDataSource>((ref) {
  return FirestoreChatDataSource();
});

/// ===========================================================
/// Chat Repository
/// ===========================================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    dataSource: ref.read(
      firestoreChatDataSourceProvider,
    ),
  );
});

/// ===========================================================
/// Chat Rooms Stream
/// ===========================================================

final chatRoomsProvider =
    StreamProvider.family<List<ChatRoomModel>, String>(
  (ref, userId) {
    return ref.watch(chatRepositoryProvider).chatRoomsStream(userId);
  },
);

/// ===========================================================
/// Messages Stream
/// ===========================================================

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>(
  (ref, roomId) {
    return ref.watch(chatRepositoryProvider).messageStream(roomId);
  },
);