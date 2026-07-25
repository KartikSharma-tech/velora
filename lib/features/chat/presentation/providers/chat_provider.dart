import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_chat_datasource.dart';
import '../../data/models/chat_room_model.dart';
import '../../data/models/chat_tile_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/repositories/chat_repository.dart';

// ==========================================================
// Data Source
// ==========================================================

final firestoreChatDataSourceProvider =
    Provider<FirestoreChatDataSource>((ref) {
  return FirestoreChatDataSource();
});

// ==========================================================
// Repository
// ==========================================================

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(
    dataSource: ref.watch(
      firestoreChatDataSourceProvider,
    ),
  );
});

// ==========================================================
// Chat Rooms
// ==========================================================

final chatRoomsProvider =
    StreamProvider.family<List<ChatRoomModel>, String>((
  ref,
  userId,
) {
  return ref.watch(chatRepositoryProvider).chatRoomsStream(userId);
});

// ==========================================================
// Chat Tiles
// ==========================================================

final chatTilesProvider =
    StreamProvider.family<List<ChatTileModel>, String>((
  ref,
  currentUserId,
) {
  return ref.watch(chatRepositoryProvider).getChatTiles(currentUserId);
});

// ==========================================================
// Messages
// ==========================================================

final messagesProvider =
    StreamProvider.family<List<MessageModel>, String>((
  ref,
  roomId,
) {
  return ref.watch(chatRepositoryProvider).messageStream(roomId);
});