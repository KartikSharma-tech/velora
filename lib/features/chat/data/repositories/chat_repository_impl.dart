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
  ) {
    return _dataSource.markLastMessageSeen(roomId);
  }
}