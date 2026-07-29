class ChatTileModel {
  final String roomId;

  final String otherUserId;

  final String otherUserName;

  final String otherUserPhoto;

  final String lastMessage;

  final DateTime lastMessageTime;

  final bool lastMessageSeen;

  final bool otherUserOnline;

  final DateTime otherUserLastSeen;

  final bool isPinned;

  const ChatTileModel({
    required this.roomId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSeen,
    required this.otherUserOnline,
    required this.otherUserLastSeen,
    this.isPinned = false,
  });

  ChatTileModel copyWith({
    String? roomId,
    String? otherUserId,
    String? otherUserName,
    String? otherUserPhoto,
    String? lastMessage,
    DateTime? lastMessageTime,
    bool? lastMessageSeen,
    bool? otherUserOnline,
    DateTime? otherUserLastSeen,
    bool? isPinned,
  }) {
    return ChatTileModel(
      roomId: roomId ?? this.roomId,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserPhoto: otherUserPhoto ?? this.otherUserPhoto,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSeen: lastMessageSeen ?? this.lastMessageSeen,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserLastSeen: otherUserLastSeen ?? this.otherUserLastSeen,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
