import '../../domain/repositories/chat_repository.dart';
import '../datasources/firestore_chat_datasource.dart';
import '../models/chat_room_model.dart';
import '../models/chat_tile_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required this._dataSource,
  });

  final FirestoreChatDataSource _dataSource;

  // ==========================================================
  // Chat Room
  // ==========================================================

  @override
  Future<String> createChatRoom({
    required List<String> participants,
  }) {
    return _dataSource.createChatRoom(
      participants: participants,
    );
  }

  @override
  Stream<List<ChatRoomModel>> chatRoomsStream(
    String userId,
  ) {
    return _dataSource.chatRoomsStream(userId);
  }

  @override
  Stream<List<ChatTileModel>> getChatTiles(
    String currentUserId,
  ) {
    return _dataSource.getChatTiles(currentUserId);
  }

  // ==========================================================
  // Messages
  // ==========================================================

  @override
  Future<void> sendMessage(
    MessageModel message,
  ) {
    return _dataSource.sendMessage(message);
  }

  @override
  Stream<List<MessageModel>> messageStream(
    String roomId,
  ) {
    return _dataSource.messageStream(roomId);
  }

  // ==========================================================
  // Seen
  // ==========================================================

  @override
  Future<void> markLastMessageSeen(
    String roomId,
  ) 
  {
    return _dataSource.markLastMessageSeen(roomId);
  }
// ==========================================================
// Delivered
// ==========================================================

@override
Future<void> markMessageDelivered({
  required String roomId,
  required String messageId,
}) {
  return _dataSource.markMessageDelivered(
    roomId: roomId,
    messageId: messageId,
  );
}

// ==========================================================
// Seen
// ==========================================================

@override
Future<void> markMessageSeen({
  required String roomId,
  required String messageId,
}) {
  return _dataSource.markMessageSeen(
    roomId: roomId,
    messageId: messageId,
  );
}
  // ==========================================================
  // Delete Message
  // ==========================================================

  @override
  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String userId,
  }) {
    return _dataSource.deleteMessageForMe(
      roomId: roomId,
      messageId: messageId,
      userId: userId,
    );
  }

  @override
  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
  }) {
    return _dataSource.deleteMessageForEveryone(
      roomId: roomId,
      messageId: messageId,
    );
  }

  // ==========================================================
  // Reactions
  // ==========================================================

  @override
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String? emoji,
  }) {
    return _dataSource.toggleReaction(
      roomId: roomId,
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );
  }

  // ==========================================================
  // Typing Indicator
  // ==========================================================

  @override
  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) {
    return _dataSource.setTyping(
      roomId: roomId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  @override
  Stream<List<String>> typingStream(String roomId) {
    return _dataSource.typingStream(roomId);
  }

  // ==========================================================
  // Pinned Chats
  // ==========================================================

  @override
  Future<void> togglePinChat({
    required String roomId,
    required String userId,
    required bool pin,
  }) {
    return _dataSource.togglePinChat(roomId: roomId, userId: userId, pin: pin);
  }
}