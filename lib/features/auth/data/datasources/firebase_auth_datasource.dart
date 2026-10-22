import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  /// ------------------------------------------------------------
  /// Current User
  /// ------------------------------------------------------------

  User? get currentUser => _firebaseAuth.currentUser;

  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  String? get currentPhoneNumber => _firebaseAuth.currentUser?.phoneNumber;

  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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
        password: password,
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
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to create account.');
    }
  }

  Future<String> linkVerifiedPhone(PhoneAuthCredential credential) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');
    final result = await user.linkWithCredential(credential);
    await result.user?.getIdToken(true);
    await result.user?.reload();
    final phoneNumber = _firebaseAuth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw Exception('Phone verification did not complete.');
    }
    return phoneNumber;
  }

  Future<void> deleteCurrentUser() async {
    await _firebaseAuth.currentUser?.delete();
  }

  /// ------------------------------------------------------------
  /// Update Display Name
  /// ------------------------------------------------------------

  Future<void> updateDisplayName(String name) async {
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

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
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
    try {
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
    } catch (_) {}
    await _firebaseAuth.signOut();
  }
}
