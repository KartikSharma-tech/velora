import '../../data/models/chat_request_model.dart';

abstract class ChatRequestRepository {
  Future<void> sendRequest({
    required String fromUserId,
    required String fromUserName,
    required String fromUserPhoto,
    required String toUserId,
    required String toUserName,
    required String toUserPhoto,
    required String message,
  });

  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  });

  Stream<List<ChatRequestModel>> incomingRequestsStream(String userId);

  Stream<List<ChatRequestModel>> outgoingRequestsStream(String userId);

  Future<ChatRequestModel?> getRequestBetween({
    required String fromUserId,
    required String toUserId,
  });
}
