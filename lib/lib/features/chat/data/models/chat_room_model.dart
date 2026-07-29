import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// BUG FIX: this used to serialize [lastMessageTime]/[createdAt] as
  /// ISO-8601 strings, but `FirestoreChatDataSource.sendMessage()`
  /// overwrites `lastMessageTime` with a Firestore [Timestamp] on
  /// every message. The next `fromMap()` then called
  /// `DateTime.parse(Timestamp)` and threw at runtime — the chat
  /// list / home screen stream crashed the moment a room had its
  /// first message sent. Both fields now consistently use
  /// [Timestamp], matching every write path.
  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: _readTimestamp(map['lastMessageTime']),
      lastMessageSeen: map['lastMessageSeen'] ?? false,
      createdAt: _readTimestamp(map['createdAt']),
      pinnedBy: List<String>.from(map['pinnedBy'] ?? const []),
      typingUsers: List<String>.from(map['typingUsers'] ?? const []),
    );
  }

  /// Defensively accepts either a [Timestamp] (normal case) or a
  /// legacy ISO-8601 [String] (any room documents created before
  /// this fix) so existing Firestore data doesn't break on read.
  static DateTime _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSeen': lastMessageSeen,
      'createdAt': Timestamp.fromDate(createdAt),
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
