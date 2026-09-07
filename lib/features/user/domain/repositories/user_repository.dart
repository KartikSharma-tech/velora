import '../../data/models/user_model.dart';

abstract class UserRepository {
  Future<void> createUser(UserModel user);

  Future<UserModel?> getUser(String uid);

  Stream<UserModel?> userStream(String uid);

  Stream<List<UserModel>> getAllUsers();
Future<List<UserModel>> searchUsersByUsername(String query);
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String about,
    required String photoUrl,
      required String username,

  });

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  });

  Future<void> updateLastSeen(String uid);

  Future<void> deleteUser(String uid);

  Future<void> blockUser({required String uid, required String blockedUid});

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  });
}