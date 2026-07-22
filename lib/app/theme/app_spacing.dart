import 'package:flutter/widgets.dart';

/// ===========================================================
/// Velora Design System
/// App Spacing
/// -----------------------------------------------------------
///
/// Single source of truth for spacing.
/// Never use hardcoded EdgeInsets or spacing values.
///
/// Example:
/// Padding(
///   padding: AppSpacing.screenPadding,
/// )
///
/// SizedBox(height: AppSpacing.lg)
///
/// ===========================================================

@immutable
final class AppSpacing {
  const AppSpacing._();

  // ===========================================================
  // Base Scale
  // ===========================================================

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 56;
  static const double ultra = 64;

  // ===========================================================
  // Screen Padding
  // ===========================================================

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );

  static const EdgeInsets screenVertical = EdgeInsets.symmetric(
    vertical: lg,
  );

  // ===========================================================
  // Page Sections
  // ===========================================================

  static const EdgeInsets section = EdgeInsets.symmetric(
    vertical: xxl,
  );

  static const EdgeInsets sectionSmall = EdgeInsets.symmetric(
    vertical: lg,
  );

  // ===========================================================
  // Card
  // ===========================================================

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);

  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xxl);

  // ===========================================================
  // List Item
  // ===========================================================

  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // ===========================================================
  // Buttons
  // ===========================================================

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: xxl,
    vertical: md,
  );

  static const EdgeInsets buttonSmallPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  static const EdgeInsets buttonLargePadding = EdgeInsets.symmetric(
    horizontal: xxxl,
    vertical: lg,
  );

  // ===========================================================
  // Inputs
  // ===========================================================

  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  // ===========================================================
  // Chat
  // ===========================================================

  static const EdgeInsets chatBubblePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets chatBubbleMargin = EdgeInsets.symmetric(
    horizontal: sm,
    vertical: xs,
  );

  static const EdgeInsets messageListPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );

  // ===========================================================
  // Avatar
  // ===========================================================

  static const double avatarXS = 24;
  static const double avatarSM = 32;
  static const double avatarMD = 40;
  static const double avatarLG = 48;
  static const double avatarXL = 56;
  static const double avatarXXL = 72;
  static const double avatarHero = 96;

  // ===========================================================
  // Icons
  // ===========================================================

  static const double iconXS = 12;
  static const double iconSM = 16;
  static const double iconMD = 20;
  static const double iconLG = 24;
  static const double iconXL = 28;
  static const double iconXXL = 32;
  static const double iconHero = 48;

  // ===========================================================
  // Divider
  // ===========================================================

  static const double divider = 1;

  // ===========================================================
  // Chat Composer
  // ===========================================================

  static const double composerMinHeight = 52;
  static const double composerMaxHeight = 140;

  // ===========================================================
  // Bottom Navigation
  // ===========================================================

  static const double bottomBarHeight = 68;

  // ===========================================================
  // App Bar
  // ===========================================================

  static const double appBarHeight = 64;

  // ===========================================================
  // Search Bar
  // ===========================================================

  static const double searchBarHeight = 52;

  // ===========================================================
  // FAB
  // ===========================================================

  static const double fabSize = 60;

  // ===========================================================
  // Chat Bubble Max Width
  // ===========================================================

  static const double chatBubbleMaxWidthFactor = 0.78;

  // ===========================================================
  // Story Ring
  // ===========================================================

  static const double storyRingWidth = 3;

  // ===========================================================
  // Common Gaps
  // ===========================================================

  static const SizedBox gapXXS = SizedBox(height: xxs);
  static const SizedBox gapXS = SizedBox(height: xs);
  static const SizedBox gapSM = SizedBox(height: sm);
  static const SizedBox gapMD = SizedBox(height: md);
  static const SizedBox gapLG = SizedBox(height: lg);
  static const SizedBox gapXL = SizedBox(height: xl);
  static const SizedBox gapXXL = SizedBox(height: xxl);
  static const SizedBox gapXXXL = SizedBox(height: xxxl);

  static const SizedBox gapWXS = SizedBox(width: xs);
  static const SizedBox gapWSM = SizedBox(width: sm);
  static const SizedBox gapWMD = SizedBox(width: md);
  static const SizedBox gapWLG = SizedBox(width: lg);
  static const SizedBox gapWXL = SizedBox(width: xl);
  static const SizedBox gapWXXL = SizedBox(width: xxl);
}