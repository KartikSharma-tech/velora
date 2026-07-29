class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final bool lastMessageSeen;
  final DateTime createdAt;

  /// userIds who currently have this chat pinned.
  final List<String> pinnedBy;

  /// userIds who are currently typing in this room.
  final List<String> typingUsers;

  const ChatRoomModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.lastMessageSeen,
    required this.createdAt,
    this.pinnedBy = const [],
    this.typingUsers = const [],
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
      lastMessageSeen: map['lastMessageSeen'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      pinnedBy: List<String>.from(map['pinnedBy'] ?? const []),
      typingUsers: List<String>.from(map['typingUsers'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageSeen': lastMessageSeen,
      'createdAt': createdAt.toIso8601String(),
      'pinnedBy': pinnedBy,
      'typingUsers': typingUsers,
    };
  }

  ChatRoomModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    bool? lastMessageSeen,
    DateTime? createdAt,
    List<String>? pinnedBy,
    List<String>? typingUsers,
  }) {
    return ChatRoomModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSeen: lastMessageSeen ?? this.lastMessageSeen,
      createdAt: createdAt ?? this.createdAt,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}
