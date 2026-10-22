import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../../../../core/services/notification_service.dart';
import '../../../user/data/models/user_model.dart';
import '../../../user/domain/repositories/user_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._remoteDataSource,
    required this._userRepository,
  });

  final FirebaseAuthDataSource _remoteDataSource;
  final UserRepository _userRepository;

  @override
  String? get currentUserId => _remoteDataSource.currentUserId;

  @override
  bool get isLoggedIn => _remoteDataSource.isLoggedIn;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _remoteDataSource.signIn(email: email, password: password);
    final user = _remoteDataSource.currentUser;
    if (user == null || !user.emailVerified) return;

    final uid = user.uid;
    if (await _userRepository.getUser(uid) != null) return;
    final now = DateTime.now();
    final displayName = user.displayName?.trim();
    await _userRepository.createUser(
      UserModel(
        uid: uid,
        name: displayName == null || displayName.isEmpty
            ? 'Velora User'
            : displayName,
        email: user.email ?? email.trim(),
        photoUrl: user.photoURL ?? '',
        about: "Hey there! I'm using Velora.",
        isOnline: false,
        lastSeen: now,
        createdAt: now,
        updatedAt: now,
        phoneNumber: user.phoneNumber ?? '',
      ),
    );
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required PhoneAuthCredential? phoneCredential,
  }) async {
    await _remoteDataSource.signUp(email: email, password: password);

    var verifiedPhone = '';
    if (phoneCredential != null) {
      try {
        verifiedPhone = await _remoteDataSource.linkVerifiedPhone(
          phoneCredential,
        );
      } catch (_) {
        try {
          await _remoteDataSource.deleteCurrentUser();
        } catch (_) {}
        rethrow;
      }
      if (verifiedPhone != phone) {
        try {
          await _remoteDataSource.deleteCurrentUser();
        } catch (_) {}
        throw StateError('Verified phone number does not match.');
      }
    }

    await _remoteDataSource.updateDisplayName(name);

    await _remoteDataSource.sendEmailVerification();
    await _remoteDataSource.signOut();
  }

  @override
  Future<String> verifyAndLinkPhoneNumber(
    PhoneAuthCredential? credential,
  ) async {
    final currentUid = _remoteDataSource.currentUserId;
    if (currentUid == null) throw StateError('Sign in before linking a phone.');

    final existingPhone = _remoteDataSource.currentPhoneNumber;
    final verifiedPhone = existingPhone ?? await _linkNewPhone(credential);
    await _userRepository.updateVerifiedPhoneNumber(
      uid: currentUid,
      phoneNumber: verifiedPhone,
    );
    return verifiedPhone;
  }

  Future<String> _linkNewPhone(PhoneAuthCredential? credential) {
    if (credential == null) throw ArgumentError.notNull('credential');
    return _remoteDataSource.linkVerifiedPhone(credential);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _remoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() {
    return _remoteDataSource.sendEmailVerification();
  }

  @override
  Future<void> reloadUser() {
    return _remoteDataSource.reloadUser();
  }

  @override
  Future<void> signOut() async {
    await NotificationService.instance.unregisterCurrentDevice();
    await _remoteDataSource.signOut();
  }
}
