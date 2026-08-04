import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRequestStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  const ChatRequestStatus(this.storageValue);

  final String storageValue;

  static ChatRequestStatus fromStorage(String? value) {
    return ChatRequestStatus.values.firstWhere(
      (e) => e.storageValue == value,
      orElse: () => ChatRequestStatus.pending,
    );
  }
}

/// A pending "may I message you" request, required whenever the
/// target's `whoCanMessage` privacy setting is
/// `contactsAndRequests` and the sender isn't already a matched
/// contact.
class ChatRequestModel {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhoto;
  final String toUserId;
  final String toUserName;
  final String toUserPhoto;
  final String message;
  final ChatRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ChatRequestModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserPhoto,
    required this.toUserId,
    required this.toUserName,
    required this.toUserPhoto,
    required this.message,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Deterministic id — one active request per (sender, receiver)
  /// pair, so re-sending after a decline replaces rather than
  /// spams duplicate docs.
  static String buildId({required String fromUserId, required String toUserId}) {
    return '${fromUserId}_$toUserId';
  }

  factory ChatRequestModel.fromMap(Map<String, dynamic> map) {
    return ChatRequestModel(
      id: map['id'] ?? '',
      fromUserId: map['fromUserId'] ?? '',
      fromUserName: map['fromUserName'] ?? '',
      fromUserPhoto: map['fromUserPhoto'] ?? '',
      toUserId: map['toUserId'] ?? '',
      toUserName: map['toUserName'] ?? '',
      toUserPhoto: map['toUserPhoto'] ?? '',
      message: map['message'] ?? '',
      status: ChatRequestStatus.fromStorage(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt: map['respondedAt'] != null
          ? (map['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhoto': fromUserPhoto,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'toUserPhoto': toUserPhoto,
      'message': message,
      'status': status.storageValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt == null ? null : Timestamp.fromDate(respondedAt!),
    };
  }
}
