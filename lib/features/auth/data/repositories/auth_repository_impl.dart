import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

import '../../../user/data/models/user_model.dart';
import '../../../user/domain/repositories/user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource remoteDataSource,
    required UserRepository userRepository,
  })  : _remoteDataSource = remoteDataSource,
        _userRepository = userRepository;

  final FirebaseAuthDataSource _remoteDataSource;
  final UserRepository _userRepository;

  @override
  String? get currentUserId => _remoteDataSource.currentUserId;

  @override
  bool get isLoggedIn => _remoteDataSource.isLoggedIn;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _remoteDataSource.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _remoteDataSource.signUp(
      email: email,
      password: password,
    );

    await _remoteDataSource.updateDisplayName(name);

    final uid = _remoteDataSource.currentUserId;

    if (uid == null) {
      throw Exception('User not found after signup.');
    }

    final user = UserModel(
      uid: uid,
      name: name,
      email: email,
      photoUrl: '',
      about: "Hey there! I'm using Velora.",
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _userRepository.createUser(user);

    await _remoteDataSource.sendEmailVerification();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _remoteDataSource.sendPasswordResetEmail(
      email: email,
    );
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.signOut();
  }
}