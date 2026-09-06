import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../shared/enums/privacy_enums.dart';
// enum Discoverability { phoneNumber, username, hidden }

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
  final String? username;
  final String? bio;
  final int usernameChangeCount;
  final DateTime? usernameLastReset;
  final List<String> blockedUsers;
  final String phoneNumber;

  final Discoverability discoverability;
  final WhoCanMessage whoCanMessage;
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

    this.username,
    this.bio,
    this.usernameChangeCount = 0,
    this.usernameLastReset,
    this.blockedUsers = const [],

    this.phoneNumber = '',
    this.discoverability = Discoverability.phoneNumber,
    this.whoCanMessage = WhoCanMessage.contactsAndRequests,
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
      username: map['username'],
      bio: map['bio'],
      usernameChangeCount: map['usernameChangeCount'] ?? 0,
      usernameLastReset: _readTimestamp(map['usernameLastReset']),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? const []),
      phoneNumber: map['phoneNumber'] ?? '',

      discoverability: Discoverability.fromStorage(
        map['discoverability'] as String?,
      ),
      whoCanMessage: WhoCanMessage.fromStorage(
  map['whoCanMessage'],
),
    );
  }
  static DateTime? _readTimestamp(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
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

      'discoverability': discoverability.storageValue,
      'whoCanMessage': whoCanMessage.storageValue,
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
    String? username,
    String? bio,
    int? usernameChangeCount,
    DateTime? usernameLastReset,
    String? phoneNumber,
    Discoverability? discoverability,
    WhoCanMessage? whoCanMessage,
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
      username: username ?? this.username,
      bio: bio ?? this.bio,
      usernameChangeCount: usernameChangeCount ?? this.usernameChangeCount,
      usernameLastReset: usernameLastReset ?? this.usernameLastReset,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      discoverability: discoverability ?? this.discoverability,
      
    );
  }
}
