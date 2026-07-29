import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// ------------------------------------------------------------
  /// Current User
  /// ------------------------------------------------------------

  User? get currentUser => _firebaseAuth.currentUser;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  Stream<User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  /// ------------------------------------------------------------
  /// Login
  /// ------------------------------------------------------------

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to sign in.');
    }
  }

  /// ------------------------------------------------------------
  /// Signup
  /// ------------------------------------------------------------

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to create account.');
    }
  }

  /// ------------------------------------------------------------
  /// Update Display Name
  /// ------------------------------------------------------------

  Future<void> updateDisplayName(
    String name,
  ) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  /// ------------------------------------------------------------
  /// Email Verification
  /// ------------------------------------------------------------

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }

  /// ------------------------------------------------------------
  /// Forgot Password
  /// ------------------------------------------------------------

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to send reset email.');
    }
  }

  /// ------------------------------------------------------------
  /// Logout
  /// ------------------------------------------------------------

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}