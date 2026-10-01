import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/velora_contact.dart';

class FirestoreContactsMatchDataSource {
  FirestoreContactsMatchDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Firestore whereIn max 30 hai — 25 safe rakho
  static const int _batchSize = 25;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Batch query — normalized phones ko Firestore users se match karo
  /// Returns: Map<normalizedPhone, VeloraContact>
  Future<Map<String, VeloraContact>> fetchVeloraUsers(
    List<String> normalizedPhones,
  ) async {
    if (normalizedPhones.isEmpty) return {};

    final unique = normalizedPhones.toSet().toList();
    final result = <String, VeloraContact>{};

    for (var i = 0; i < unique.length; i += _batchSize) {
      final batch = unique.sublist(
        i,
        (i + _batchSize > unique.length) ? unique.length : i + _batchSize,
      );

      final snapshot = await _users
          .where('phoneNumber', whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final phone = data['phoneNumber'] as String?;
        if (phone == null) continue;

        result[phone] = VeloraContact(
          displayName: data['name'] as String? ?? 'Velora User',
          phone: phone,
          isOnVelora: true,
          uid: doc.id,
          veloraName: data['name'] as String?,
          photoUrl: data['photoUrl'] as String?,
          username: data['username'] as String?,
        );
      }
    }

    return result;
  }
}