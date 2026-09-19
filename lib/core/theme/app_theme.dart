import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';

/// Accessibility switches that change how surfaces are drawn. Read by
/// `RelayCard` and text fields so features don't need to know about them.
@immutable
class RelayAccessibilityTheme extends ThemeExtension<RelayAccessibilityTheme> {
  const RelayAccessibilityTheme({this.highContrast = false});

  /// Adds visible borders to cards and inputs ("High Contrast Borders").
  final bool highContrast;

  @override
  RelayAccessibilityTheme copyWith({bool? highContrast}) =>
      RelayAccessibilityTheme(highContrast: highContrast ?? this.highContrast);

  @override
  RelayAccessibilityTheme lerp(ThemeExtension<RelayAccessibilityTheme>? other, double t) =>
      other is RelayAccessibilityTheme && t >= 0.5 ? other : this;
}

abstract final class AppTheme {
  static ThemeData light({bool highContrast = false}) =>
      _build(AppPalette.light, highContrast: highContrast);

  static ThemeData dark({bool highContrast = false}) =>
      _build(AppPalette.dark, highContrast: highContrast);

  static ThemeData _build(AppPalette p, {required bool highContrast}) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.onPrimaryContainer,
      secondary: p.secondary,
      onSecondary: p.isDark ? p.onAmber : p.onPrimary,
      secondaryContainer: p.peach,
      onSecondaryContainer: p.onPeachStrong,
      tertiary: p.brandMuted,
      onTertiary: p.onPrimary,
      error: p.error,
      onError: p.isDark ? p.onAmber : p.onErrorFill,
      errorContainer: p.errorContainer,
      onErrorContainer: p.escalationTitle,
      surface: p.background,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      outline: p.outline,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: p.surfaceLow,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceHigh,
      surfaceContainerHighest: p.surfaceHighest,
      inverseSurface: p.inverseSurface,
      onInverseSurface: p.onInverseSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      fontFamily: 'PlusJakartaSans',
      // Every slot carries `onSurface`, so text without an explicit colour is
      // readable in either theme; call sites override per role.
      textTheme: TextTheme(
        bodyLarge: AppTypography.bodyReading,
        bodyMedium: AppTypography.base,
        bodySmall: AppTypography.caption,
        titleMedium: AppTypography.label16,
        titleSmall: AppTypography.label14,
        labelLarge: AppTypography.label14,
        labelMedium: AppTypography.caption,
        headlineSmall: AppTypography.headline,
      ).apply(bodyColor: p.onSurface, displayColor: p.onSurface),
      splashFactory: InkRipple.splashFactory,
      dividerColor: p.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brand),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brand,
        selectionColor: p.brand.withValues(alpha: 0.3),
        selectionHandleColor: p.brandContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.inverseSurface,
        contentTextStyle: AppTypography.label14.copyWith(color: p.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        p,
        RelayAccessibilityTheme(highContrast: highContrast),
      ],
    );
  }
}
