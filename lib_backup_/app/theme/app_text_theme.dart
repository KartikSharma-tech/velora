import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// ===========================================================
/// Velora Design System
/// Text Theme
/// -----------------------------------------------------------
///
/// Bridges AppTypography with Flutter's TextTheme.
/// Exposes light and dark variants.
///
/// ===========================================================

@immutable
final class AppTextTheme {
  const AppTextTheme._();

  // ===========================================================
  // Light Text Theme
  // ===========================================================

  static final TextTheme light = TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(
      color: AppColors.textPrimary,
    ),
    displayMedium: AppTypography.displayMedium.copyWith(
      color: AppColors.textPrimary,
    ),
    displaySmall: AppTypography.displaySmall.copyWith(
      color: AppColors.textPrimary,
    ),
    headlineLarge: AppTypography.headlineLarge.copyWith(
      color: AppColors.textPrimary,
    ),
    headlineMedium: AppTypography.headlineMedium.copyWith(
      color: AppColors.textPrimary,
    ),
    headlineSmall: AppTypography.headlineSmall.copyWith(
      color: AppColors.textPrimary,
    ),
    titleLarge: AppTypography.titleLarge.copyWith(
      color: AppColors.textPrimary,
    ),
    titleMedium: AppTypography.titleMedium.copyWith(
      color: AppColors.textPrimary,
    ),
    titleSmall: AppTypography.titleSmall.copyWith(
      color: AppColors.textSecondary,
    ),
    bodyLarge: AppTypography.bodyLarge.copyWith(
      color: AppColors.textPrimary,
    ),
    bodyMedium: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    bodySmall: AppTypography.bodySmall.copyWith(
      color: AppColors.textHint,
    ),
    labelLarge: AppTypography.labelLarge.copyWith(
      color: AppColors.textPrimary,
    ),
    labelMedium: AppTypography.labelMedium.copyWith(
      color: AppColors.textSecondary,
    ),
    labelSmall: AppTypography.labelSmall.copyWith(
      color: AppColors.textHint,
    ),
  );

  // ===========================================================
  // Dark Text Theme
  // ===========================================================

  static final TextTheme dark = TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    displayMedium: AppTypography.displayMedium.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    displaySmall: AppTypography.displaySmall.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineLarge: AppTypography.headlineLarge.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: AppTypography.headlineMedium.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    headlineSmall: AppTypography.headlineSmall.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleLarge: AppTypography.titleLarge.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: AppTypography.titleMedium.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: AppTypography.titleSmall.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    bodyLarge: AppTypography.bodyLarge.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    bodySmall: AppTypography.bodySmall.copyWith(
      color: AppColors.textHintDark,
    ),
    labelLarge: AppTypography.labelLarge.copyWith(
      color: AppColors.textPrimaryDark,
    ),
    labelMedium: AppTypography.labelMedium.copyWith(
      color: AppColors.textSecondaryDark,
    ),
    labelSmall: AppTypography.labelSmall.copyWith(
      color: AppColors.textHintDark,
    ),
  );
}