import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuthDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final FirebaseAuthDataSource _remoteDataSource;

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