import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  String? get currentUserId;
  bool get isLoggedIn;

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required PhoneAuthCredential? phoneCredential,
  });

  Future<String> verifyAndLinkPhoneNumber(PhoneAuthCredential? credential);

  Future<void> sendEmailVerification();

  Future<void> reloadUser();
  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();
}
