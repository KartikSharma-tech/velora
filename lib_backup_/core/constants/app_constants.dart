class AppConstants {
  AppConstants._();

  // ===========================================================
  // App
  // ===========================================================

  static const String appName = 'Velora';

  static const String appVersion = '1.0.0';

  static const String packageName = 'com.velora.app';

  // ===========================================================
  // Animation
  // ===========================================================

  static const Duration splashDuration = Duration(seconds: 2);

  static const Duration animationDuration = Duration(milliseconds: 300);

  static const Duration pageTransitionDuration =
      Duration(milliseconds: 250);

  // ===========================================================
  // Pagination
  // ===========================================================

  static const int pageSize = 20;

  // ===========================================================
  // Chat
  // ===========================================================

  static const int maxMessageLength = 5000;

  static const int maxGroupMembers = 1024;

  static const int typingIndicatorSeconds = 5;

  // ===========================================================
  // Images
  // ===========================================================

  static const int imageQuality = 85;

  static const int imageMaxWidth = 1440;

  static const int imageMaxHeight = 1440;

  // ===========================================================
  // Cache
  // ===========================================================

  static const Duration cacheDuration = Duration(days: 7);

  // ===========================================================
  // Hive Boxes
  // ===========================================================

  static const String settingsBox = 'settings';

  static const String userBox = 'user';

  static const String chatBox = 'chat';

  static const String messageBox = 'messages';

  static const String notificationBox = 'notifications';

  // ===========================================================
  // Assets
  // ===========================================================

  static const String logo = 'assets/images/logo.png';

  static const String logoDark = 'assets/images/logo_dark.png';

  static const String defaultAvatar =
      'assets/images/default_avatar.png';
}