import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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

    final batch = _firestore.batch();
    batch.set(messageRef, message.toMap());

    final previewText = message.type == 'image' && message.text.isEmpty
        ? 'Photo'
        : message.text;

    final roomRef = _chatRooms.doc(message.chatRoomId);
    batch.update(roomRef, {
      'lastMessage': previewText,
      'lastMessageId': message.id,
      'lastMessageSenderId': message.senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSeen': false,
      // A new message restores this room only for its sender if they hid it.
      'deletedBy': FieldValue.arrayRemove([message.senderId]),
    });
    await batch.commit();
  }

  // ==========================================================
  // Mark Message Delivered
  // ==========================================================

  Future<void> markMessageDelivered({
    required String roomId,
    required String messageId,
  }) async {
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update({
      'isDelivered': true,
      'deliveredAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==========================================================
  // Mark Message Seen
  // ==========================================================

  Future<void> markMessageSeen({
    required String roomId,
    required String messageId,
  }) async {
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update({
      'isSeen': true,
      'seenAt': Timestamp.fromDate(DateTime.now()),
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
        .limitToLast(50)
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
        .limit(30)
        .snapshots()
        .handleError((e) {
          debugPrint('chatRoomsStream error: $e');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((e) => ChatRoomModel.fromMap(e.data()))
              .toList();
        });
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
        .snapshots()
        .asyncMap((snapshot) async {
          final List<ChatTileModel> chats = [];

          for (final doc in snapshot.docs) {
            final room = ChatRoomModel.fromMap(doc.data());

            if (room.deletedBy.contains(currentUserId)) {
              continue;
            }

            final otherUserId = room.participants.firstWhere(
              (id) => id != currentUserId,
            );

            UserModel? user;
            try {
              final userDoc = await _firestore
                  .collection('public_profiles')
                  .doc(otherUserId)
                  .get();
              if (userDoc.exists) {
                user = UserModel.fromMap(userDoc.data()!);
              }
            } catch (_) {
              // Keep legacy chats visible when a public profile is unavailable.
            }
            chats.add(
              ChatTileModel(
                roomId: room.id,
                otherUserId: user?.uid ?? otherUserId,
                otherUserName: user?.name ?? 'Velora User',
                otherUserPhoto: user?.photoUrl ?? '',
                lastMessage: room.lastMessage,
                lastMessageTime: room.lastMessageTime,
                lastMessageSeen: room.lastMessageSeen,
                otherUserOnline: user?.isOnline ?? false,
                otherUserLastSeen: user?.lastSeen ?? room.lastMessageTime,
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
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update({
      'deletedFor': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> deleteMessageForEveryone({
    required String roomId,
    required String messageId,
  }) async {
    await _chatRooms.doc(roomId).collection('messages').doc(messageId).update({
      'isDeletedForEveryone': true,
      'text': '',
      'imageUrl': null,
      'reactions': <String, String>{},
    });
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

  Future<void> deleteChatForMe({
    required String roomId,
    required String userId,
  }) async {
    await _chatRooms.doc(roomId).update({
      'deletedBy': FieldValue.arrayUnion([userId]),
      'pinnedBy': FieldValue.arrayRemove([userId]),
    });
  }

  // ==========================================================
  // Image Upload
  // ==========================================================

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