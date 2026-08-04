import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/firestore_user_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';

/// ===========================================================
/// Firestore DataSource
/// ===========================================================

final firestoreUserDataSourceProvider =
    Provider<FirestoreUserDataSource>((ref) {
  return FirestoreUserDataSource();
});

/// ===========================================================
/// User Repository
/// ===========================================================

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    dataSource: ref.read(firestoreUserDataSourceProvider),
  );
});

/// ===========================================================
/// Current User Stream
/// ===========================================================

final currentUserProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).userStream(uid);
});

/// ===========================================================
/// All Users Stream
/// ===========================================================

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(userRepositoryProvider).getAllUsers();
});

/// ===========================================================
/// Username Search
/// -----------------------------------------------------------
/// One-shot, family-keyed by the raw query string so each distinct
/// search re-fetches (Riverpod caches per-argument automatically).
/// ===========================================================

final usernameSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  final trimmed = query.trim().toLowerCase();
  if (trimmed.isEmpty) return [];

  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return [];

  return ref.watch(userRepositoryProvider).searchByUsername(
        trimmed,
        excludeUid: currentUserId,
      );
});