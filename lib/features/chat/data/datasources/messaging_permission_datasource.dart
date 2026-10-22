import 'dart:convert';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../../domain/services/messaging_permission.dart';

class MessagingPermissionDataSource {
  MessagingPermissionDataSource({
    FirebaseAuth? auth,
    FirebaseAppCheck? appCheck,
    http.Client? client,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance,
       _client = client ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseAppCheck _appCheck;
  final http.Client _client;

  Uri get _endpoint => Uri.https(
    'us-central1-${Firebase.app().options.projectId}.cloudfunctions.net',
    '/resolveMessagingPermission',
  );

  Future<MessagingPermission> resolve({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != currentUserId || !user.emailVerified) {
      return MessagingPermission.blocked;
    }

    final idToken = await user.getIdToken();
    final appCheckToken = await _appCheck.getToken();
    if (appCheckToken == null) return MessagingPermission.blocked;

    final response = await _client
        .post(
          _endpoint,
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
            'X-Firebase-AppCheck': appCheckToken,
          },
          body: jsonEncode({'targetUid': targetUserId}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Messaging permission check failed.');
    }

    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return switch (result['permission']) {
      'allowed' => MessagingPermission.allowed,
      'request_required' => MessagingPermission.requestRequired,
      _ => MessagingPermission.blocked,
    };
  }
}
