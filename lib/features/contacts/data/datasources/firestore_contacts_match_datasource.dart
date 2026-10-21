import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/velora_contact.dart';

class FirestoreContactsMatchDataSource {
  FirestoreContactsMatchDataSource({FirebaseAuth? auth, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final http.Client _client;

  static const int _batchSize = 250;
  Uri get _lookupUri => Uri.https(
    'us-central1-${Firebase.app().options.projectId}.cloudfunctions.net',
    '/lookupVeloraContacts',
  );

  /// Contact numbers are matched on the server; private user documents are not
  /// directly queryable by other clients.
  Future<Map<String, VeloraContact>> fetchVeloraUsers(
    List<String> normalizedPhones,
  ) async {
    if (normalizedPhones.isEmpty) return {};

    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('Sign in with a verified account to find contacts.');
    }
    final idToken = await user.getIdToken();
    final appCheckToken = await FirebaseAppCheck.instance.getToken();
    if (appCheckToken == null) {
      throw StateError('Unable to verify this app and account.');
    }

    final phones = normalizedPhones.toSet().toList();
    final result = <String, VeloraContact>{};
    for (var i = 0; i < phones.length; i += _batchSize) {
      final batch = phones.skip(i).take(_batchSize).toList();
      final response = await _client
          .post(
            _lookupUri,
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
              'X-Firebase-AppCheck': appCheckToken,
            },
            body: jsonEncode({'phones': batch}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw StateError('Contact lookup failed (${response.statusCode}).');
      }

      final matches = jsonDecode(response.body) as List<dynamic>;
      for (final match in matches) {
        final data = Map<String, dynamic>.from(match as Map);
        final phone = data['phoneNumber'] as String?;
        if (phone == null || phone.isEmpty) continue;
        result[phone] = VeloraContact(
          displayName: data['name'] as String? ?? 'Velora User',
          phone: phone,
          isOnVelora: true,
          uid: data['uid'] as String?,
          veloraName: data['name'] as String?,
          photoUrl: data['photoUrl'] as String?,
          username: data['username'] as String?,
        );
      }
    }
    return result;
  }
}
