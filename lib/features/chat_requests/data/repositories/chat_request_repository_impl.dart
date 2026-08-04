import '../../domain/repositories/chat_request_repository.dart';
import '../datasources/firestore_chat_request_datasource.dart';
import '../models/chat_request_model.dart';

class ChatRequestRepositoryImpl implements ChatRequestRepository {
  ChatRequestRepositoryImpl({required this._dataSource});

  final FirestoreChatRequestDataSource _dataSource;

  @override
  Future<void> sendRequest({
    required String fromUserId,
    required String fromUserName,
    required String fromUserPhoto,
    required String toUserId,
    required String toUserName,
    required String toUserPhoto,
    required String message,
  }) {
    return _dataSource.sendRequest(
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      fromUserPhoto: fromUserPhoto,
      toUserId: toUserId,
      toUserName: toUserName,
      toUserPhoto: toUserPhoto,
      message: message,
    );
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  }) {
    return _dataSource.respondToRequest(requestId: requestId, accept: accept);
  }

  @override
  Stream<List<ChatRequestModel>> incomingRequestsStream(String userId) {
    return _dataSource.incomingRequestsStream(userId);
  }

  @override
  Stream<List<ChatRequestModel>> outgoingRequestsStream(String userId) {
    return _dataSource.outgoingRequestsStream(userId);
  }

  @override
  Future<ChatRequestModel?> getRequestBetween({
    required String fromUserId,
    required String toUserId,
  }) {
    return _dataSource.getRequestBetween(
      fromUserId: fromUserId,
      toUserId: toUserId,
    );
  }
}
