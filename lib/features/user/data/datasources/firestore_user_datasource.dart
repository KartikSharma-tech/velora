import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/enums/privacy_enums.dart';
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

  // ==========================================================
  // Update Profile
  // ==========================================================

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String about,
    required String photoUrl,
  }) async {
    await _users.doc(uid).update({
      'name': name,
      'about': about,
      'photoUrl': photoUrl,
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

  // ==========================================================
  // Username
  // ==========================================================

  Future<bool> isUsernameAvailable(String username, {String? excludeUid}) async {
    final snapshot =
        await _users.where('username', isEqualTo: username).limit(2).get();

    if (snapshot.docs.isEmpty) return true;
    if (snapshot.docs.length > 1) return false;

    // Available if the only doc holding it is this same user
    // (re-saving their own unchanged username).
    return excludeUid != null && snapshot.docs.first.id == excludeUid;
  }

  Future<void> updateUsername({
    required String uid,
    required String username,
  }) async {
    await _users.doc(uid).update({
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Prefix search — Firestore has no case-insensitive `contains`,
  /// so usernames are always stored lowercase and this does a
  /// `[query, query + '\uf8ff')` range scan, which is the standard
  /// Firestore "starts with" pattern.
  Future<List<UserModel>> searchByUsername(
    String query, {
    required String excludeUid,
  }) async {
    if (query.isEmpty) return [];

    final snapshot = await _users
        .orderBy('username')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .limit(20)
        .get();

    return snapshot.docs
        .map((e) => UserModel.fromMap(e.data()))
        .where((u) => u.uid != excludeUid)
        .where((u) => u.discoverability == Discoverability.username)
        .toList();
  }

  // ==========================================================
  // Phone Number
  // ==========================================================

  Future<void> updatePhoneNumber({
    required String uid,
    required String phoneNumber,
  }) async {
    await _users.doc(uid).update({
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // Privacy Settings
  // ==========================================================

  Future<void> updatePrivacySettings({
    required String uid,
    required WhoCanMessage whoCanMessage,
    required Discoverability discoverability,
  }) async {
    await _users.doc(uid).update({
      'whoCanMessage': whoCanMessage.storageValue,
      'discoverability': discoverability.storageValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}