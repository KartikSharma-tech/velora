import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class FirestoreUserDataSource {
  FirestoreUserDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_collection);

  // ==========================================================
  // Create User
  // ==========================================================

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  // ==========================================================
  // Get User
  // ==========================================================

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  // ==========================================================
  // Current User Stream
  // ==========================================================

  Stream<UserModel?> userStream(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;

      return UserModel.fromMap(snapshot.data()!);
    });
  }

  // ==========================================================
  // Get All Users
  // ==========================================================

  Stream<List<UserModel>> getAllUsers() {
    return _users
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((e) => UserModel.fromMap(e.data()))
              .toList(),
        );
  }

  Future<List<UserModel>> searchUsersByUsername(String query) async {
  if (query.trim().isEmpty) return [];

  final snapshot = await _users
      .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
      .where('username',
          isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
      .limit(20)
      .get();

  return snapshot.docs
      .map((doc) => UserModel.fromMap(doc.data()))
      .toList();
}

  // ==========================================================
  // Update Profile
  // ==========================================================
Future<bool> isUsernameTaken(String username) async {
  final snapshot = await _users
      .where('username', isEqualTo: username)
      .limit(1)
      .get();

  return snapshot.docs.isNotEmpty;
}
  Future<void> updateProfile({
  required String uid,
  required String name,
  required String about,
  required String photoUrl,
  required String username,
}) async {
  final currentUser = await _users.doc(uid).get();

final currentUsername = currentUser.data()?['username'];

if (username != currentUsername) {
  final exists = await isUsernameTaken(username);

  if (exists) {
    throw Exception('Username already taken');
  }
}
    await _users.doc(uid).update({
  'name': name,
  'about': about,
  'photoUrl': photoUrl,
  'username': username,
  'updatedAt': FieldValue.serverTimestamp(),
});
  }

  // ==========================================================
  // Online Status
  // ==========================================================

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    await _users.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // Last Seen
  // ==========================================================

  Future<void> updateLastSeen(String uid) async {
    await _users.doc(uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // Delete User
  // ==========================================================

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  // ==========================================================
  // Block / Unblock
  // ==========================================================

  Future<void> blockUser({
    required String uid,
    required String blockedUid,
  }) async {
    await _users.doc(uid).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser({
    required String uid,
    required String blockedUid,
  }) async {
    await _users.doc(uid).update({
      'blockedUsers': FieldValue.arrayRemove([blockedUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}