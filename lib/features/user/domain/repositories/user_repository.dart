import '../../../../shared/enums/privacy_enums.dart';
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

  Future<void> blockUser({required String uid, required String blockedUid});

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  });

  // ==========================================================
  // Username
  // ==========================================================

  Future<bool> isUsernameAvailable(String username, {String? excludeUid});

  Future<void> updateUsername({
    required String uid,
    required String username,
  });

  Future<List<UserModel>> searchByUsername(
    String query, {
    required String excludeUid,
  });

  // ==========================================================
  // Phone Number
  // ==========================================================

  Future<void> updatePhoneNumber({
    required String uid,
    required String phoneNumber,
  });

  // ==========================================================
  // Privacy Settings
  // ==========================================================

  Future<void> updatePrivacySettings({
    required String uid,
    required WhoCanMessage whoCanMessage,
    required Discoverability discoverability,
  });
}
