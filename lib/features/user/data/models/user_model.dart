import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../shared/enums/privacy_enums.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String about;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> blockedUsers;

  /// E.164-ish normalized phone number (digits only, no spaces/
  /// dashes/parens). Empty string if the user hasn't added one —
  /// contact-matching simply can't find them until they do.
  final String phoneNumber;

  /// Unique, lowercase handle used for username search. Empty
  /// string if not set yet.
  final String username;

  final WhoCanMessage whoCanMessage;
  final Discoverability discoverability;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.about,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.blockedUsers = const [],
    this.phoneNumber = '',
    this.username = '',
    this.whoCanMessage = WhoCanMessage.contactsAndRequests,
    this.discoverability = Discoverability.username,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      about: map['about'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? const []),
      phoneNumber: map['phoneNumber'] ?? '',
      username: map['username'] ?? '',
      whoCanMessage: WhoCanMessage.fromStorage(map['whoCanMessage']),
      discoverability: Discoverability.fromStorage(map['discoverability']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'about': about,
      'isOnline': isOnline,
      'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'blockedUsers': blockedUsers,
      'phoneNumber': phoneNumber,
      'username': username,
      'whoCanMessage': whoCanMessage.storageValue,
      'discoverability': discoverability.storageValue,
    };
  }

  bool hasBlocked(String uid) => blockedUsers.contains(uid);

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? about,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? blockedUsers,
    String? phoneNumber,
    String? username,
    WhoCanMessage? whoCanMessage,
    Discoverability? discoverability,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      about: about ?? this.about,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      username: username ?? this.username,
      whoCanMessage: whoCanMessage ?? this.whoCanMessage,
      discoverability: discoverability ?? this.discoverability,
    );
  }
}
