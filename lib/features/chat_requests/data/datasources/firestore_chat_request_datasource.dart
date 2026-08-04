import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_request_model.dart';

class FirestoreChatRequestDataSource {
  FirestoreChatRequestDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('chat_requests');

  // ==========================================================
  // Send Request
  // ==========================================================

  Future<void> sendRequest({
    required String fromUserId,
    required String fromUserName,
    required String fromUserPhoto,
    required String toUserId,
    required String toUserName,
    required String toUserPhoto,
    required String message,
  }) async {
    final id = ChatRequestModel.buildId(
      fromUserId: fromUserId,
      toUserId: toUserId,
    );

    final request = ChatRequestModel(
      id: id,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      toUserId: toUserId,
      toUserName: toUserName,
      toUserPhoto: toUserPhoto,
      message: message,
      status: ChatRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    await _requests.doc(id).set(request.toMap());
  }

  // ==========================================================
  // Respond
  // ==========================================================

  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  }) async {
    await _requests.doc(requestId).update({
      'status': accept
          ? ChatRequestStatus.accepted.storageValue
          : ChatRequestStatus.declined.storageValue,
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ==========================================================
  // Streams
  // ==========================================================

  Stream<List<ChatRequestModel>> incomingRequestsStream(String userId) {
    return _requests
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: ChatRequestStatus.pending.storageValue)
        .snapshots()
        .map((snapshot) {
      final requests =
          snapshot.docs.map((e) => ChatRequestModel.fromMap(e.data())).toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    });
  }

  Stream<List<ChatRequestModel>> outgoingRequestsStream(String userId) {
    return _requests.where('fromUserId', isEqualTo: userId).snapshots().map(
      (snapshot) {
        final requests = snapshot.docs
            .map((e) => ChatRequestModel.fromMap(e.data()))
            .toList();
        requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return requests;
      },
    );
  }

  // ==========================================================
  // One-shot status check (messaging permission gate)
  // ==========================================================

  Future<ChatRequestModel?> getRequestBetween({
    required String fromUserId,
    required String toUserId,
  }) async {
    final id = ChatRequestModel.buildId(fromUserId: fromUserId, toUserId: toUserId);
    final doc = await _requests.doc(id).get();
    if (!doc.exists) return null;
    return ChatRequestModel.fromMap(doc.data()!);
  }
}
