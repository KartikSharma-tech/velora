import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../user/data/models/user_model.dart';

/// Matches normalized phone numbers (from the device address book)
/// against registered `users` in Firestore.
class FirestoreContactsMatchDataSource {
  FirestoreContactsMatchDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _batchSize = 10;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Looks up which of [normalizedPhoneNumbers] belong to a
  /// registered, phone-discoverable user. Firestore's `whereIn`
  /// caps at 30 values (we use 10 per query to stay safely under
  /// that on every SDK version), so a large contact list is looked
  /// up in batches and merged.
  Future<List<UserModel>> findRegisteredUsers(
    List<String> normalizedPhoneNumbers, {
    required String excludeUid,
  }) async {
    if (normalizedPhoneNumbers.isEmpty) return [];

    final uniqueNumbers = normalizedPhoneNumbers.toSet().toList();
    final results = <UserModel>[];

    for (var i = 0; i < uniqueNumbers.length; i += _batchSize) {
      final batch = uniqueNumbers.sublist(
        i,
        (i + _batchSize > uniqueNumbers.length)
            ? uniqueNumbers.length
            : i + _batchSize,
      );

      final snapshot =
          await _users.where('phoneNumber', whereIn: batch).get();

      for (final doc in snapshot.docs) {
        if (doc.id == excludeUid) continue;
        results.add(UserModel.fromMap(doc.data()));
      }
    }

    return results;
  }
}
