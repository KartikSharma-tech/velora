import 'package:firebase_auth/firebase_auth.dart' show User;
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
/// Live Firebase Auth State
/// -----------------------------------------------------------
/// BUG FIX: currentUserIdProvider / authStateProvider used to be
/// plain `Provider`s that read `_remoteDataSource.currentUserId`
/// once and cached it forever — they never rebuilt after
/// login/signup/logout because their only dependency
/// (authRepositoryProvider) never itself changes identity.
/// That silently broke home/chat/profile/settings screens after
/// auth transitions. Now driven by the real Firebase stream.
/// ===========================================================

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthDataSourceProvider).authStateChanges;
});

/// ===========================================================
/// Auth State
/// ===========================================================

final authStateProvider = Provider<bool>((ref) {
  return ref.watch(currentUserIdProvider) != null;
});

/// ===========================================================
/// Current User Id
/// ===========================================================

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) => user?.uid,
    loading: () => ref.read(firebaseAuthDataSourceProvider).currentUserId,
    error: (_, _) => null,
  );
});
