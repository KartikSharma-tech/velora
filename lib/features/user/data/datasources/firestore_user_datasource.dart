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
}