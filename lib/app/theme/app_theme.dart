import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_text_theme.dart';

/// ===========================================================
/// Velora Design System
/// App Theme
/// -----------------------------------------------------------
///
/// Central theme configuration.
///
/// Exposes:
/// - lightTheme
/// - darkTheme
///
/// ===========================================================

@immutable
final class AppTheme {
  const AppTheme._();

  // ===========================================================
  // Light Theme
  // ===========================================================

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: colorScheme,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      canvasColor: AppColors.surface,
      dividerColor: AppColors.divider,

      splashColor: AppColors.primary.withValues(alpha: .08),
      highlightColor: Colors.transparent,

      textTheme: AppTextTheme.light,

      fontFamily: 'Inter',

      visualDensity: VisualDensity.adaptivePlatformDensity,

      // =======================================================
      // App Bar
      // =======================================================

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,

        titleTextStyle: AppTextTheme.light.titleLarge,

        iconTheme: const IconThemeData(
          color: AppColors.iconPrimary,
          size: 24,
        ),
      ),

      // =======================================================
      // Cards
      // =======================================================

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
        ),
      ),

      // =======================================================
      // Divider
      // =======================================================

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // =======================================================
      // Floating Action Button
      // =======================================================

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // =======================================================
      // Progress Indicator
      // =======================================================

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surfaceVariant,
      ),

      // =======================================================
      // Tooltip
      // =======================================================

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: AppRadius.md,
        ),
        textStyle: AppTextTheme.dark.bodySmall,
      ),

      // =======================================================
      // List Tile
      // =======================================================

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.iconPrimary,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }

  // ===========================================================
  // Dark Theme
  // ===========================================================

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: colorScheme,

      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      canvasColor: AppColors.surfaceDark,
      dividerColor: AppColors.dividerDark,

      splashColor: AppColors.primary.withValues(alpha: .12),
      highlightColor: Colors.transparent,

      textTheme: AppTextTheme.dark,

      fontFamily: 'Inter',

      visualDensity: VisualDensity.adaptivePlatformDensity,
            // =======================================================
      // App Bar
      // =======================================================

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextTheme.dark.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.iconPrimaryDark,
          size: 24,
        ),
      ),

      // =======================================================
      // Input Decoration
      // =======================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,

        contentPadding: AppSpacing.inputPadding,

        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(
            color: AppColors.inputBorderDark,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(
            color: AppColors.inputBorderDark,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),

        hintStyle: AppTextTheme.dark.bodyMedium?.copyWith(
          color: AppColors.textHintDark,
        ),

        labelStyle: AppTextTheme.dark.bodyMedium?.copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // =======================================================
      // Elevated Button
      // =======================================================

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: AppSpacing.buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTextTheme.dark.labelLarge,
        ),
      ),

      // =======================================================
      // Outlined Button
      // =======================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.primary,
          padding: AppSpacing.buttonPadding,
          side: const BorderSide(
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTextTheme.dark.labelLarge,
        ),
      ),

      // =======================================================
      // Text Button
      // =======================================================

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: AppSpacing.buttonPadding,
          textStyle: AppTextTheme.dark.labelLarge,
        ),
      ),

      // =======================================================
      // Navigation Bar
      // =======================================================

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primary.withValues(alpha: .15),
        elevation: 0,
        height: AppSpacing.bottomBarHeight,

        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextTheme.dark.labelMedium?.copyWith(
                color: AppColors.primary,
              );
            }

            return AppTextTheme.dark.labelMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            );
          },
        ),

        iconTheme: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                color: AppColors.primary,
                size: 24,
              );
            }

            return const IconThemeData(
              color: AppColors.iconSecondaryDark,
              size: 24,
            );
          },
        ),
      ),

      // =======================================================
      // Bottom Navigation Bar
      // =======================================================

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.iconSecondaryDark,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // =======================================================
      // Search Bar
      // =======================================================

      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(
          AppColors.inputFillDark,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: AppRadius.search,
          ),
        ),
        padding: WidgetStateProperty.all(
          AppSpacing.inputPadding,
        ),
      ),      // =======================================================
      // Card
      // =======================================================

      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
        ),
      ),

      // =======================================================
      // Dialog
      // =======================================================

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
        ),
        titleTextStyle: AppTextTheme.dark.titleLarge,
        contentTextStyle: AppTextTheme.dark.bodyMedium,
      ),

      // =======================================================
      // Bottom Sheet
      // =======================================================

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.bottomSheet,
        ),
      ),

      // =======================================================
      // SnackBar
      // =======================================================

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextTheme.light.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
        ),
      ),

      // =======================================================
      // Divider
      // =======================================================

      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),

      // =======================================================
      // Checkbox
      // =======================================================

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sm,
        ),
        side: const BorderSide(
          color: AppColors.dividerDark,
        ),
      ),

      // =======================================================
      // Radio
      // =======================================================

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.iconSecondaryDark;
        }),
      ),

      // =======================================================
      // Switch
      // =======================================================

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.dividerDark;
        }),
      ),

      // =======================================================
      // Progress Indicator
      // =======================================================

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.surfaceVariantDark,
      ),

      // =======================================================
      // Floating Action Button
      // =======================================================

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      // =======================================================
      // Tooltip
      // =======================================================

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimaryDark,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.darkSm,
        ),
        textStyle: AppTextTheme.light.bodySmall,
      ),

      // =======================================================
      // List Tile
      // =======================================================

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.iconPrimaryDark,
        textColor: AppColors.textPrimaryDark,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}