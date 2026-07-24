import '../../data/models/user_model.dart';

abstract class UserRepository {
  Future<void> createUser(UserModel user);

  Future<UserModel?> getUser(String uid);

  Stream<UserModel?> userStream(String uid);

  Stream<List<UserModel>> getAllUsers();

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String about,
    required String photoUrl,
  });

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  });

  Future<void> updateLastSeen(String uid);

  Future<void> deleteUser(String uid);
}