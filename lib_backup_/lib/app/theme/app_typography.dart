import 'package:flutter/material.dart';

/// ===========================================================
/// Velora Design System
/// Typography
/// -----------------------------------------------------------
///
/// Font Family:
/// Inter
///
/// Use these styles as the base for the application's
/// TextTheme.
///
/// ===========================================================

@immutable
final class AppTypography {
  const AppTypography._();

  // ===========================================================
  // Font Family
  // ===========================================================

  static const String fontFamily = 'Inter';

  // ===========================================================
  // Font Weights
  // ===========================================================

  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // ===========================================================
  // Base Style
  // ===========================================================

  static const TextStyle base = TextStyle(
    fontFamily: fontFamily,
    color: Colors.black,
    fontWeight: regular,
    height: 1.35,
    letterSpacing: 0,
  );

  // ===========================================================
  // Display
  // ===========================================================

  static TextStyle get displayLarge => base.copyWith(
        fontSize: 40,
        fontWeight: extraBold,
      );

  static TextStyle get displayMedium => base.copyWith(
        fontSize: 34,
        fontWeight: bold,
      );

  static TextStyle get displaySmall => base.copyWith(
        fontSize: 30,
        fontWeight: bold,
      );

  // ===========================================================
  // Headlines
  // ===========================================================

  static TextStyle get headlineLarge => base.copyWith(
        fontSize: 28,
        fontWeight: bold,
      );

  static TextStyle get headlineMedium => base.copyWith(
        fontSize: 24,
        fontWeight: semiBold,
      );

  static TextStyle get headlineSmall => base.copyWith(
        fontSize: 20,
        fontWeight: semiBold,
      );

  // ===========================================================
  // Titles
  // ===========================================================

  static TextStyle get titleLarge => base.copyWith(
        fontSize: 18,
        fontWeight: semiBold,
      );

  static TextStyle get titleMedium => base.copyWith(
        fontSize: 16,
        fontWeight: medium,
      );

  static TextStyle get titleSmall => base.copyWith(
        fontSize: 14,
        fontWeight: medium,
      );

  // ===========================================================
  // Body
  // ===========================================================

  static TextStyle get bodyLarge => base.copyWith(
        fontSize: 16,
      );

  static TextStyle get bodyMedium => base.copyWith(
        fontSize: 15,
      );

  static TextStyle get bodySmall => base.copyWith(
        fontSize: 13,
      );

  // ===========================================================
  // Labels
  // ===========================================================

  static TextStyle get labelLarge => base.copyWith(
        fontSize: 14,
        fontWeight: medium,
      );

  static TextStyle get labelMedium => base.copyWith(
        fontSize: 12,
        fontWeight: medium,
      );

  static TextStyle get labelSmall => base.copyWith(
        fontSize: 11,
        fontWeight: medium,
      );

  // ===========================================================
  // Buttons
  // ===========================================================

  static TextStyle get button => base.copyWith(
        fontSize: 15,
        fontWeight: semiBold,
      );

  // ===========================================================
  // Chat
  // ===========================================================

  static TextStyle get message => base.copyWith(
        fontSize: 15,
        height: 1.45,
      );

  static TextStyle get messageTime => base.copyWith(
        fontSize: 11,
        fontWeight: medium,
      );

  static TextStyle get username => base.copyWith(
        fontSize: 14,
        fontWeight: semiBold,
      );

  // ===========================================================
  // Caption
  // ===========================================================

  static TextStyle get caption => base.copyWith(
        fontSize: 12,
      );

  static TextStyle get overline => base.copyWith(
        fontSize: 10,
        fontWeight: medium,
        letterSpacing: .8,
      );
}