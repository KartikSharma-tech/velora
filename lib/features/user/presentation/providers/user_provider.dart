import 'package:flutter_riverpod/flutter_riverpod.dart';

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