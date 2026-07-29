import 'package:flutter/widgets.dart';

/// ===========================================================
/// Velora Design System
/// Border Radius
/// -----------------------------------------------------------
///
/// Use AppRadius everywhere.
/// Never use BorderRadius.circular() directly in UI.
///
/// Example:
///
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: AppRadius.lg,
///   ),
/// )
///
/// ===========================================================

@immutable
final class AppRadius {
  const AppRadius._();

  // ===========================================================
  // Radius Values
  // ===========================================================

  static const double noneValue = 0;
  static const double xsValue = 4;
  static const double smValue = 8;
  static const double mdValue = 12;
  static const double lgValue = 16;
  static const double xlValue = 20;
  static const double xxlValue = 24;
  static const double xxxlValue = 32;
  static const double pillValue = 100;
  static const double circleValue = 999;

  // ===========================================================
  // BorderRadius
  // ===========================================================

  static const BorderRadius none =
      BorderRadius.all(Radius.circular(noneValue));

  static const BorderRadius xs =
      BorderRadius.all(Radius.circular(xsValue));

  static const BorderRadius sm =
      BorderRadius.all(Radius.circular(smValue));

  static const BorderRadius md =
      BorderRadius.all(Radius.circular(mdValue));

  static const BorderRadius lg =
      BorderRadius.all(Radius.circular(lgValue));

  static const BorderRadius xl =
      BorderRadius.all(Radius.circular(xlValue));

  static const BorderRadius xxl =
      BorderRadius.all(Radius.circular(xxlValue));

  static const BorderRadius xxxl =
      BorderRadius.all(Radius.circular(xxxlValue));

  static const BorderRadius pill =
      BorderRadius.all(Radius.circular(pillValue));

  static const BorderRadius circle =
      BorderRadius.all(Radius.circular(circleValue));

  // ===========================================================
  // Components
  // ===========================================================

  /// Primary Buttons
  static const BorderRadius button = lg;

  /// TextField
  static const BorderRadius input = lg;

  /// Card
  static const BorderRadius card = xl;

  /// Bottom Sheet
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: Radius.circular(28),
    topRight: Radius.circular(28),
  );

  /// Dialog
  static const BorderRadius dialog = xxl;

  /// Chat Bubble (Sender)
  static const BorderRadius senderBubble = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(6),
  );

  /// Chat Bubble (Receiver)
  static const BorderRadius receiverBubble = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(18),
  );

  /// Avatar
  static const BorderRadius avatar = circle;

  /// Image Preview
  static const BorderRadius image = xl;

  /// Search Bar
  static const BorderRadius search = pill;

  /// Chips
  static const BorderRadius chip = pill;

  /// FAB
  static const BorderRadius fab = circle;

  /// Menu
  static const BorderRadius menu = lg;

  /// Snackbar
  static const BorderRadius snackbar = lg;

  /// Notification Card
  static const BorderRadius notification = xl;

  /// Story Ring
  static const BorderRadius story = circle;

  /// Profile Header
  static const BorderRadius profileHeader = BorderRadius.only(
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(32),
  );
}