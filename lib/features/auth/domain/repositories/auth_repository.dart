abstract class AuthRepository {
  String? get currentUserId;
  bool get isLoggedIn;

  Future<void> signIn({
    required String email,
    required String password,
  });

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  });
Future<void> sendEmailVerification();

Future<void> reloadUser();
  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<void> signOut();
}