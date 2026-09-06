import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../models/chat_tile_model.dart';
import '../../../user/data/models/user_model.dart';

class FirestoreChatDataSource {
  FirestoreChatDataSource({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinary,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cloudinary = cloudinary ?? const CloudinaryService();

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinary;

  CollectionReference<Map<String, dynamic>> get _chatRooms =>
      _firestore.collection('chat_rooms');

  // ==========================================================
  // Create Chat Room
  // ==========================================================

  Future<String> createChatRoom({required List<String> participants}) async {
    participants.sort();

    final roomId = participants.join('_');

    final roomDoc = _chatRooms.doc(roomId);

    final snapshot = await roomDoc.get();

    if (!snapshot.exists) {
      final room = ChatRoomModel(
        id: roomId,
        participants: participants,
        lastMessage: '',
        lastMessageSenderId: '',
        lastMessageTime: DateTime.now(),
        lastMessageSeen: true,
        createdAt: DateTime.now(),
      );

      await roomDoc.set(room.toMap());
    }

    return roomId;
  }
  // =========================================================
  Future<bool> chatRoomExists(List<String> participants) async {
  final ids = [...participants]..sort();

  final roomId = ids.join('_');

  final doc = await _chatRooms.doc(roomId).get();

  return doc.exists;
}

  // ==========================================================
  // Send Message
  // ==========================================================

  Future<void> sendMessage(MessageModel message) async {
    final messageRef = _chatRooms
        .doc(message.chatRoomId)
        .collection('messages')
        .doc(message.id);

    await messageRef.set(message.toMap());

    final previewText = message.type == 'image' && message.text.isEmpty
        ? '📷 Photo'
        : message.text;

    await _chatRooms.doc(message.chatRoomId).update({
      'lastMessage': previewText,
      'lastMessageSenderId': message.senderId,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'lastMessageSeen': false,
    });
  }// ==========================================================
// Mark Message Delivered
// ==========================================================

Future<void> markMessageDelivered({
  required String roomId,
  required String messageId,
  
}) 

async {
  await _chatRooms
      .doc(roomId)
      .collection('messages')
      .doc(messageId)
      .update({
    'isDelivered': true,
    'deliveredAt': DateTime.now().toIso8601String(),
  });
}
// ==========================================================
// Mark Message Seen
// ==========================================================

Future<void> markMessageSeen({
  required String roomId,
  required String messageId,
}) async {
  await _chatRooms
      .doc(roomId)
      .collection('messages')
      .doc(messageId)
      .update({
    'isSeen': true,
    'seenAt': DateTime.now().toIso8601String(),
  });
}
  // ==========================================================
  // Messages Stream
  // ==========================================================

  Stream<List<MessageModel>> messageStream(String roomId) {
    return _chatRooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((e) => MessageModel.fromMap(e.data())).toList(),
        );
  }

  // ==========================================================
  // Chat Rooms Stream
  // ==========================================================

  Stream<List<ChatRoomModel>> chatRoomsStream(String userId) {
    return _chatRooms
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((e) => ChatRoomModel.fromMap(e.data()))
              .toList(),
        );
  }

  // ==========================================================
  // Mark Last Message Seen
  // ==========================================================

  Future<void> markLastMessageSeen(String roomId) async {
    await _chatRooms.doc(roomId).update({'lastMessageSeen': true});
  }

  // ==========================================================
  // Chat Tiles Stream
  // ==========================================================

  Stream<List<ChatTileModel>> getChatTiles(String currentUserId) {
    return _chatRooms
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<ChatTileModel> chats = [];

          for (final doc in snapshot.docs) {
            final room = ChatRoomModel.fromMap(doc.data());

            final otherUserId = room.participants.firstWhere(
              (id) => id != currentUserId,
            );

            final userDoc = await _firestore
                .collection('users')
                .doc(otherUserId)
                .get();

            if (!userDoc.exists) {
              continue;
            }

            final user = UserModel.fromMap(userDoc.data()!);

            chats.add(
              ChatTileModel(
                roomId: room.id,
                otherUserId: user.uid,
                otherUserName: user.name,
                otherUserPhoto: user.photoUrl,
                lastMessage: room.lastMessage,
                lastMessageTime: room.lastMessageTime,
                lastMessageSeen: room.lastMessageSeen,
                otherUserOnline: user.isOnline,
                // otherUserLastSeen: user.lastSeen,
                otherUserLastSeen: user.lastSeen ?? DateTime.now(),
                isPinned: room.pinnedBy.contains(currentUserId),
              ),
            );
          }

          chats.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            return b.lastMessageTime.compareTo(a.lastMessageTime);
          });

          return chats;
        });
  }

  // ==========================================================
  // Delete Message
  // ==========================================================

  Future<void> deleteMessageForMe({
    required String roomId,
    required String messageId,
    required String userId,
  }) async {
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update(
      {
        'deletedFor': FieldValue.arrayUnion([userId]),
      },
    );
  }

  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
  }) async {
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update(
      {
        'isDeletedForEveryone': true,
        'text': '',
        'imageUrl': null,
        'reactions': <String, String>{},
      },
    );
  }

  // ==========================================================
  // Reactions
  // ==========================================================

  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String? emoji,
  }) async {
    final ref = _chatRooms.doc(roomId).collection('messages').doc(messageId);

    if (emoji == null) {
      await ref.update({'reactions.$userId': FieldValue.delete()});
    } else {
      await ref.update({'reactions.$userId': emoji});
    }
  }

  // ==========================================================
  // Typing Indicator
  // ==========================================================

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) async {
    await _chatRooms.doc(roomId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }

  Stream<List<String>> typingStream(String roomId) {
    return _chatRooms.doc(roomId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return const [];
      return List<String>.from(data['typingUsers'] ?? const []);
    });
  }

  // ==========================================================
  // Pinned Chats
  // ==========================================================

  Future<void> togglePinChat({
    required String roomId,
    required String userId,
    required bool pin,
  }) async {
    await _chatRooms.doc(roomId).update({
      'pinnedBy': pin
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }

  // ==========================================================
  // Image Upload
  // ==========================================================

  /// Uploads a local image file to
  /// `chat_images/{roomId}/{messageId}.jpg` in Firebase Storage
  /// and returns its public download URL. Called *before*
  /// `sendMessage()` — the resulting URL is what actually gets
  /// saved on the message doc.
  Future<String> uploadChatImage({
    required String roomId,
    required String messageId,
    required File file,
  }) async {
    return _cloudinary.uploadImage(
      file: file,
      folder: 'chat_images/$roomId',
      publicId: messageId,
    );
  }
}
