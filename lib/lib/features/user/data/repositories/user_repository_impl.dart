import '../../domain/repositories/user_repository.dart';
import '../datasources/firestore_user_datasource.dart';
import '../models/user_model.dart';
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl({
    required FirestoreUserDataSource dataSource,
  }) : _dataSource = dataSource;

  final FirestoreUserDataSource _dataSource;

  @override
  Future<void> createUser(UserModel user) {
    return _dataSource.createUser(user);
  }

  @override
  Future<UserModel?> getUser(String uid) {
    return _dataSource.getUser(uid);
  }

  @override
  Stream<UserModel?> userStream(String uid) {
    return _dataSource.userStream(uid);
  }

  @override
  Stream<List<UserModel>> getAllUsers() {
    return _dataSource.getAllUsers();
  }

  @override
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String about,
    required String photoUrl,
  }) {
    return _dataSource.updateProfile(
      uid: uid,
      name: name,
      about: about,
      photoUrl: photoUrl,
    );
  }

  @override
  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  }) {
    return _dataSource.setOnlineStatus(
      uid: uid,
      isOnline: isOnline,
    );
  }

  @override
  Future<void> updateLastSeen(String uid) {
    return _dataSource.updateLastSeen(uid);
  }

  @override
  Future<void> deleteUser(String uid) {
    return _dataSource.deleteUser(uid);
  }

  @override
  Future<void> blockUser({required String uid, required String blockedUid}) {
    return _dataSource.blockUser(uid: uid, blockedUid: blockedUid);
  }

  @override
  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) {
    return _dataSource.unblockUser(uid: uid, blockedUid: blockedUid);
  }
}