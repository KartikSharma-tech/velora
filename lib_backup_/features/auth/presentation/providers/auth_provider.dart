import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

import '../../../user/presentation/providers/user_provider.dart';

/// ===========================================================
/// Firebase Auth DataSource
/// ===========================================================

final firebaseAuthDataSourceProvider =
    Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

/// ===========================================================
/// Auth Repository
/// ===========================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(
      firebaseAuthDataSourceProvider,
    ),
    userRepository: ref.read(
      userRepositoryProvider,
    ),
  );
});

/// ===========================================================
/// Auth State
/// ===========================================================

final authStateProvider = Provider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isLoggedIn;
});

/// ===========================================================
/// Current User Id
/// ===========================================================

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).currentUserId;
});