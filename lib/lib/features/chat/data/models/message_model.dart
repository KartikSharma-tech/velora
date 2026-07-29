class MessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String receiverId;
  final String text;
  final String type;
  final DateTime timestamp;
  final bool isSeen;
  final String? imageUrl;

  /// Reply-to (denormalized so the bubble can render the quoted
  /// snippet without an extra lookup).
  final String? replyToId;
  final String? replyToText;
  final String? replyToSenderName;

  /// Delete For Me / Delete For Everyone.
  final List<String> deletedFor;
  final bool isDeletedForEveryone;

  /// Emoji reactions: userId -> emoji.
  final Map<String, String> reactions;

  const MessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.timestamp,
    required this.isSeen,
    this.imageUrl,
    this.replyToId,
    this.replyToText,
    this.replyToSenderName,
    this.deletedFor = const [],
    this.isDeletedForEveryone = false,
    this.reactions = const {},
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: DateTime.parse(map['timestamp']),
      isSeen: map['isSeen'] ?? false,
      imageUrl: map['imageUrl'],
      replyToId: map['replyToId'],
      replyToText: map['replyToText'],
      replyToSenderName: map['replyToSenderName'],
      deletedFor: List<String>.from(map['deletedFor'] ?? const []),
      isDeletedForEveryone: map['isDeletedForEveryone'] ?? false,
      reactions: Map<String, String>.from(map['reactions'] ?? const {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isSeen': isSeen,
      'imageUrl': imageUrl,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'replyToSenderName': replyToSenderName,
      'deletedFor': deletedFor,
      'isDeletedForEveryone': isDeletedForEveryone,
      'reactions': reactions,
    };
  }

  /// Whether [userId] can still see this message in their thread.
  bool isVisibleTo(String userId) => !deletedFor.contains(userId);

  MessageModel copyWith({
    String? id,
    String? chatRoomId,
    String? senderId,
    String? receiverId,
    String? text,
    String? type,
    DateTime? timestamp,
    bool? isSeen,
    String? imageUrl,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
    List<String>? deletedFor,
    bool? isDeletedForEveryone,
    Map<String, String>? reactions,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      imageUrl: imageUrl ?? this.imageUrl,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      deletedFor: deletedFor ?? this.deletedFor,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      reactions: reactions ?? this.reactions,
    );
  }
}
