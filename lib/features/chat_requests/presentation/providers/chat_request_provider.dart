import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_chat_request_datasource.dart';
import '../../data/models/chat_request_model.dart';
import '../../data/repositories/chat_request_repository_impl.dart';
import '../../domain/repositories/chat_request_repository.dart';

final firestoreChatRequestDataSourceProvider =
    Provider<FirestoreChatRequestDataSource>((ref) {
  return FirestoreChatRequestDataSource();
});

final chatRequestRepositoryProvider = Provider<ChatRequestRepository>((ref) {
  return ChatRequestRepositoryImpl(
    dataSource: ref.watch(firestoreChatRequestDataSourceProvider),
  );
});

final incomingChatRequestsProvider =
    StreamProvider.family<List<ChatRequestModel>, String>((ref, userId) {
  return ref.watch(chatRequestRepositoryProvider).incomingRequestsStream(userId);
});

final outgoingChatRequestsProvider =
    StreamProvider.family<List<ChatRequestModel>, String>((ref, userId) {
  return ref.watch(chatRequestRepositoryProvider).outgoingRequestsStream(userId);
});
