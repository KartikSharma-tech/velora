import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/router/app_router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _registeredUid;
  String? _registeredToken;
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'velora_messages',
    'Messages',
    description: 'Notifications for new Velora messages',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized ||
        kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(
        _showForegroundNotification(message).catchError((Object error) {
          debugPrint('Unable to display foreground notification: $error');
        }),
      );
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openChatFromMessage,
    );
    _authSubscription = _auth.authStateChanges().listen((user) {
      unawaited(
        _syncCurrentUser(user).catchError((Object error) {
          debugPrint('Unable to sync notification token: $error');
        }),
      );
    });
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        unawaited(
          _storeToken(uid, token).catchError((Object error) {
            debugPrint('Unable to update refreshed notification token: $error');
          }),
        );
      }
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await WidgetsBinding.instance.endOfFrame;
      _openChatFromMessage(initialMessage);
    }
  }

  Future<void> _syncCurrentUser(User? user) async {
    final previousUid = _registeredUid;
    final previousToken = _registeredToken;
    if (previousUid != null &&
        previousToken != null &&
        previousUid != user?.uid) {
      try {
        await _deleteToken(previousUid, previousToken);
      } catch (error) {
        debugPrint('Unable to unlink previous notification token: $error');
      }
    }
    _registeredUid = user?.uid;
    _registeredToken = null;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token != null) await _storeToken(user.uid, token);
  }

  /// Unlinks this device while the current Firebase user is still signed in.
  Future<void> unregisterCurrentDevice() async {
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }
    final uid = _auth.currentUser?.uid;
    final token = _registeredToken ?? await _messaging.getToken();
    if (uid != null && token != null) {
      try {
        await _deleteToken(uid, token);
      } catch (error) {
        debugPrint(
          'Unable to remove notification token from Firestore: $error',
        );
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (error) {
      debugPrint('Unable to revoke notification token: $error');
    }
    _registeredUid = null;
    _registeredToken = null;
  }

  Future<void> _storeToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    _registeredUid = uid;
    _registeredToken = token;
  }

  Future<void> _deleteToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(token)
        .delete();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = message.data;
    final title = message.notification?.title ?? 'New message';
    final body = message.notification?.body ?? 'You received a message.';
    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'velora_messages',
          'Messages',
          channelDescription: 'Notifications for new Velora messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(data),
    );
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
      _openChat(data);
    } on FormatException catch (error) {
      debugPrint('Invalid notification payload: $error');
    } on TypeError catch (error) {
      debugPrint('Invalid notification payload shape: $error');
    }
  }

  void _openChatFromMessage(RemoteMessage message) => _openChat(message.data);

  void _openChat(Map<String, dynamic> data) {
    final roomId = data['roomId'] as String?;
    final receiverId = data['senderId'] as String?;
    final receiverName = data['senderName'] as String? ?? 'Chat';
    if (roomId == null || receiverId == null || roomId.isEmpty) return;
    AppRouter.router.push(
      AppRouter.chat,
      extra: {
        'roomId': roomId,
        'receiverId': receiverId,
        'receiverName': receiverName,
      },
    );
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
  }
}
