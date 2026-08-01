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

  /// BUG FIX (Home screen crash: "type 'Timestamp' is not a subtype
  /// of type 'String'"):
  ///
  /// `toMap()` used to write `lastMessageTime` / `createdAt` as
  /// ISO-8601 strings via `.toIso8601String()`. But
  /// `FirestoreChatDataSource.sendMessage()` updates
  /// `lastMessageTime` on the room document with a real Firestore
  /// `Timestamp` (`Timestamp.fromDate(...)`) every time a message
  /// is sent. So the very first read of a brand-new, message-less
  /// room worked (still a String), but the moment *any* message
  /// was sent, the field became a `Timestamp`, and the next
  /// `fromMap()` call did `DateTime.parse(Timestamp)` — which
  /// throws, because `DateTime.parse` only accepts a `String`.
  /// That's why it only crashed "sometimes": exactly for chats
  /// that already had a message sent.
  ///
  /// Fix: both fields are now written as `Timestamp` (matching
  /// what `sendMessage()` already does), and `fromMap()` accepts
  /// either a `Timestamp` (normal, going forward) or a legacy
  /// `String` (any room docs already saved in the old format), so
  /// existing Firestore data won't crash on read either.
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

  /// Accepts a Firestore [Timestamp] (current/correct format) or a
  /// legacy ISO-8601 [String] (anything written before this fix),
  /// so old room documents don't crash the app on read.
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