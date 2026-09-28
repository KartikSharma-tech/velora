import 'package:hive/hive.dart';

part 'cached_contact_model.g.dart';

@HiveType(typeId: 3)
class CachedContactModel extends HiveObject {
  @HiveField(0)
  final String phone; // normalized E.164

  @HiveField(1)
  final String? uid; // null = not on Velora

  @HiveField(2)
  final String? veloraName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final String? username;

  @HiveField(5)
  final DateTime cachedAt;

  @HiveField(6)
  final bool isOnVelora;

  @HiveField(7)
  final String displayName; // from device contacts

  CachedContactModel({
    required this.phone,
    required this.cachedAt,
    required this.isOnVelora,
    required this.displayName,
    this.uid,
    this.veloraName,
    this.photoUrl,
    this.username,
  });

  /// Cache 24 hours se purana hai?
  bool get isExpired {
    return DateTime.now().difference(cachedAt).inHours >= 24;
  }

  /// Fresh copy with updated data
  CachedContactModel copyWith({
    String? uid,
    String? veloraName,
    String? photoUrl,
    String? username,
    bool? isOnVelora,
    String? displayName,
    DateTime? cachedAt,
  }) {
    return CachedContactModel(
      phone: phone,
      cachedAt: cachedAt ?? this.cachedAt,
      isOnVelora: isOnVelora ?? this.isOnVelora,
      displayName: displayName ?? this.displayName,
      uid: uid ?? this.uid,
      veloraName: veloraName ?? this.veloraName,
      photoUrl: photoUrl ?? this.photoUrl,
      username: username ?? this.username,
    );
  }
}