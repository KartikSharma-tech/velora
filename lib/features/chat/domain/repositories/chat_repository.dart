import '../../data/models/chat_room_model.dart';
import '../../data/models/chat_tile_model.dart';
import '../../data/models/message_model.dart';
import 'dart:io';
abstract class ChatRepository {
  // ==========================================================
  // Chat Room
  // ==========================================================

  Future<String> createChatRoom({
    required List<String> participants,
  });

  Future<bool> chatRoomExists(List<String> participants);

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
  // For Image Upload /
  
  Stream<List<MessageModel>> messageStream(
    String roomId,
  );

  // ==========================================================
  // Seen / Delivered
  // ==========================================================

  Future<void> markLastMessageSeen(
    String roomId,
  );

  Future<void> markMessageDelivered({
    required String roomId,
    required String messageId,
  });

  Future<void> markMessageSeen({
    required String roomId,
    required String messageId,
  });

  // ==========================================================
  // Delete Message
  // ==========================================================

  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String userId,
  });

  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
  });

  // ==========================================================
  // Reactions
  // ==========================================================

  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String? emoji,
  });

  // ==========================================================
  // Typing Indicator
  // ==========================================================

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  });

  Stream<List<String>> typingStream(String roomId);

  // ==========================================================
  // Pinned Chats
  // ==========================================================

  Future<void> togglePinChat({
    required String roomId,
    required String userId,
    required bool pin,
  });
}
