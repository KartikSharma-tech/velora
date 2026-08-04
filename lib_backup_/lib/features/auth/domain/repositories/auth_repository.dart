abstract class AuthRepository {
  /// Current logged-in user id
  String? get currentUserId;

  /// User login status
  bool get isLoggedIn;

  /// Login
  Future<void> signIn({
    required String email,
    required String password,
  });

  /// Signup
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Forgot password
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  /// Logout
  Future<void> signOut();
}