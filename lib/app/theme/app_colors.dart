import 'package:flutter/material.dart';

/// ===========================================================
/// Velora Design System
/// App Colors
/// -----------------------------------------------------------
///
/// Single source of truth for all colors.
///
/// Never hardcode colors inside UI.
///
/// ===========================================================

@immutable
final class AppColors {
  const AppColors._();

  // ===========================================================
  // Brand
  // ===========================================================

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFE0E7FF);

  static const Color accent = Color(0xFF3B82F6);

  // ===========================================================
  // Background
  // ===========================================================

  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);

  // ===========================================================
  // Surface
  // ===========================================================

  static const Color surface = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);

  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceVariantDark = Color(0xFF334155);

  // ===========================================================
  // Text (Light)
  // ===========================================================

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint = Color(0xFF94A3B8);

  // ===========================================================
  // Text (Dark)
  // ===========================================================

  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textHintDark = Color(0xFF94A3B8);

  // ===========================================================
  // Divider
  // ===========================================================

  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // ===========================================================
  // Icons
  // ===========================================================

  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textSecondary;

  static const Color iconPrimaryDark = Colors.white;
  static const Color iconSecondaryDark = Color(0xFFCBD5E1);

  // ===========================================================
  // Input
  // ===========================================================

  static const Color inputFill = Colors.white;
  static const Color inputFillDark = Color(0xFF1E293B);

  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color inputBorderDark = Color(0xFF475569);

  static const Color inputFocused = primary;

  // ===========================================================
  // Status
  // ===========================================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ===========================================================
  // Online / Offline
  // ===========================================================

  static const Color online = Color(0xFF22C55E);
  static const Color offline = Color(0xFF9CA3AF);

  // ===========================================================
  // Chat
  // ===========================================================

  static const Color senderBubble = primary;
  static const Color receiverBubble = surfaceVariant;

  static const Color senderBubbleDark = primary;
  static const Color receiverBubbleDark = Color(0xFF334155);  // ===========================================================
  // Avatar
  // ===========================================================

  static const Color avatarBackground = Color(0xFFE2E8F0);
  static const Color avatarBackgroundDark = Color(0xFF334155);

  // ===========================================================
  // Notification
  // ===========================================================

  static const Color notification = Color(0xFFEF4444);
  static const Color badge = Color(0xFFDC2626);

  // ===========================================================
  // Selection
  // ===========================================================

  static const Color selection = Color(0x334F46E5);

  // ===========================================================
  // Overlay
  // ===========================================================

  static const Color overlay = Color(0x80000000);

  // ===========================================================
  // Borders
  // ===========================================================

  static const Color border = divider;
  static const Color borderDark = dividerDark;

  // ===========================================================
  // Disabled
  // ===========================================================

  static const Color disabled = Color(0xFFCBD5E1);
  static const Color disabledDark = Color(0xFF475569);

  // ===========================================================
  // Chat Text
  // ===========================================================

  static const Color senderText = Colors.white;
  static const Color receiverText = textPrimary;

  static const Color senderTextDark = Colors.white;
  static const Color receiverTextDark = textPrimaryDark;

  // ===========================================================
  // Message Status
  // ===========================================================

  static const Color sent = Color(0xFF64748B);
  static const Color delivered = Color(0xFF3B82F6);
  static const Color seen = Color(0xFF22C55E);

  // ===========================================================
  // Reaction Colors
  // ===========================================================

  static const Color like = Color(0xFF2563EB);
  static const Color love = Color(0xFFEF4444);
  static const Color laugh = Color(0xFFF59E0B);
  static const Color wow = Color(0xFFF97316);
  static const Color sad = Color(0xFF6366F1);
  static const Color angry = Color(0xFFDC2626);

  // ===========================================================
  // Gradients
  // ===========================================================

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      accent,
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(0xFF10B981),
      Color(0xFF059669),
    ],
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [
      Color(0xFFEF4444),
      Color(0xFFDC2626),
    ],
  );

  // ===========================================================
  // Transparent
  // ===========================================================

  static const Color transparent = Colors.transparent;
}