/// ===========================================================
/// Velora
/// Hive Box Names
/// -----------------------------------------------------------
///
/// Single source of truth for Hive box identifiers.
/// Open these boxes once during bootstrap().
///
/// ===========================================================

class HiveBoxes {
  const HiveBoxes._();

  /// Small key/value box for local app preferences
  /// (theme mode, etc). Not for user/chat data — that lives
  /// in Firestore.
  static const String settings = 'settings_box';
}
