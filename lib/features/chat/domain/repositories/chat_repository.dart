import '../../data/models/chat_room_model.dart';
import '../../data/models/chat_tile_model.dart';
import '../../data/models/message_model.dart';

abstract class ChatRepository {
  // ==========================================================
  // Chat Room
  // ==========================================================

  Future<String> createChatRoom({
    required List<String> participants,
  });

  Stream<List<ChatRoomModel>> chatRoomsStream(
    String userId,
  );

  Stream<List<ChatTileModel>> getChatTiles(
    String currentUserId,
  );

  // ==========================================================
  // Messages
  // ==========================================================

  Future<void> sendMessage(
    MessageModel message,
  );

  Stream<List<MessageModel>> messageStream(
    String roomId,
  );

  // ==========================================================
  // Seen
  // ==========================================================

  Future<void> markLastMessageSeen(
    String roomId,
  );
}