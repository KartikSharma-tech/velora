import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class FirestoreUserDataSource {
  FirestoreUserDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'users';

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_collection);

  CollectionReference<Map<String, dynamic>> get _publicProfiles =>
      _firestore.collection('public_profiles');

  // ==========================================================
  // Create User
  // ==========================================================

  Future<void> createUser(UserModel user) async {
    final batch = _firestore.batch();
    batch.set(_users.doc(user.uid), user.toMap());
    batch.set(_publicProfiles.doc(user.uid), user.toPublicMap());
    await batch.commit();
  }

  // ==========================================================
  // Get User
  // ==========================================================

  Future<UserModel?> getUser(String uid) async {
    final reference = FirebaseAuth.instance.currentUser?.uid == uid
        ? _users.doc(uid)
        : _publicProfiles.doc(uid);
    final doc = await reference.get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);
  }

  // ==========================================================
  // Current User Stream
  // ==========================================================

  Stream<UserModel?> userStream(String uid) {
    final reference = FirebaseAuth.instance.currentUser?.uid == uid
        ? _users.doc(uid)
        : _publicProfiles.doc(uid);
    return reference.snapshots().map((snapshot) {
      if (!snapshot.exists) return null;

      return UserModel.fromMap(snapshot.data()!);
    });
  }

  // ==========================================================
  // Get All Users
  // ==========================================================

  Stream<List<UserModel>> getAllUsers() {
    return _publicProfiles
        .where('discoverability', whereIn: ['phone_number', 'username'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((e) => UserModel.fromMap(e.data())).toList(),
        );
  }

  Future<List<UserModel>> searchUsersByUsername(String query) async {
    if (query.trim().isEmpty) return [];

    final snapshot = await _publicProfiles
        .where('discoverability', isEqualTo: 'username')
        .where('username', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('username', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ==========================================================
  // Update Profile
  // ==========================================================
  Future<bool> isUsernameTaken(String username) async {
    final snapshot = await _publicProfiles
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
    final profileUpdate = {
      'name': name,
      'about': about,
      'photoUrl': photoUrl,
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    batch.update(_users.doc(uid), profileUpdate);
    batch.update(_publicProfiles.doc(uid), profileUpdate);
    await batch.commit();
  }

  // ==========================================================
  // Online Status
  // ==========================================================

  Future<void> setOnlineStatus({
    required String uid,
    required bool isOnline,
  }) async {
    final presenceUpdate = {
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    batch.update(_users.doc(uid), presenceUpdate);
    batch.update(_publicProfiles.doc(uid), presenceUpdate);
    await batch.commit();
  }

  // ==========================================================
  // Last Seen
  // ==========================================================

  Future<void> updateLastSeen(String uid) async {
    final lastSeenUpdate = {
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final batch = _firestore.batch();
    batch.update(_users.doc(uid), lastSeenUpdate);
    batch.update(_publicProfiles.doc(uid), lastSeenUpdate);
    await batch.commit();
  }

  Future<void> updateVerifiedPhoneNumber({
    required String uid,
    required String phoneNumber,
  }) async {
    await _users.doc(uid).update({
      'phoneNumber': phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // Delete User
  // ==========================================================

  Future<void> deleteUser(String uid) async {
    final batch = _firestore.batch();
    batch.delete(_users.doc(uid));
    batch.delete(_publicProfiles.doc(uid));
    await batch.commit();
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
