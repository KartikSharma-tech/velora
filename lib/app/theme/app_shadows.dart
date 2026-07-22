import 'package:flutter/material.dart';

/// ===========================================================
/// Velora Design System
/// Shadows
/// -----------------------------------------------------------
///
/// Never create BoxShadow manually in UI.
/// Always use AppShadows.
///
/// ===========================================================

@immutable
final class AppShadows {
  const AppShadows._();

  // ===========================================================
  // Light Theme
  // ===========================================================

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x10000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  // ===========================================================
  // Dark Theme
  // ===========================================================

  static const List<BoxShadow> darkSm = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> darkMd = [
    BoxShadow(
      color: Color(0x44000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkLg = [
    BoxShadow(
      color: Color(0x55000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ===========================================================
  // Components
  // ===========================================================

  static const List<BoxShadow> card = md;

  static const List<BoxShadow> dialog = lg;

  static const List<BoxShadow> bottomSheet = xl;

  static const List<BoxShadow> appBar = xs;

  static const List<BoxShadow> fab = floating;

  static const List<BoxShadow> chatBubble = sm;

  static const List<BoxShadow> profileAvatar = md;

  static const List<BoxShadow> image = lg;

  static const List<BoxShadow> menu = md;

  static const List<BoxShadow> notification = md;

  static const List<BoxShadow> searchBar = sm;

  static const List<BoxShadow> elevatedButton = sm;

  // ===========================================================
  // Glow Effects
  // ===========================================================

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x333F51B5),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> accentGlow = [
    BoxShadow(
      color: Color(0x332962FF),
      blurRadius: 22,
      spreadRadius: 2,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> successGlow = [
    BoxShadow(
      color: Color(0x3310B981),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
  ];

  static const List<BoxShadow> errorGlow = [
    BoxShadow(
      color: Color(0x33FF5A5F),
      blurRadius: 20,
      spreadRadius: 1,
      offset: Offset(0, 0),
    ),
  ];

  // ===========================================================
  // Inner Decoration Helpers
  // ===========================================================

  static const BorderSide borderLight = BorderSide(
    color: Color(0xFFE5E7EB),
    width: 1,
  );

  static const BorderSide borderDark = BorderSide(
    color: Color(0xFF353535),
    width: 1,
  );
}