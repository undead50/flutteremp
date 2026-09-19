import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';

/// Semantic colour roles for the whole app, with a light and a dark value set.
///
/// The light values are the Figma tokens verbatim. The design defines no dark
/// theme, so the dark values are derived from the same green/orange brand: a
/// green-tinted near-black surface ramp, and lighter tints for anything that is
/// *text or an icon* on those surfaces.
///
/// A few colours play two roles in the design and therefore have two tokens:
///
/// * **fill** (`primary`, `primaryContainer`, `errorFill`, `escalationFill`):
///   a solid background that carries `on…` (white) content;
/// * **content** (`brand`, `brandContainer`, `brandMuted`, `error`,
///   `escalationText`): the same hue used as text/icon/border on a surface. In
///   light mode both roles have the same value; in dark mode fills stay deep
///   enough for white text while content tints get lighter.
///
/// Read it with `context.palette`; switching theme rebuilds every dependant.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.card,
    required this.surfaceLow,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.brand,
    required this.brandContainer,
    required this.brandMuted,
    required this.mint,
    required this.onMint,
    required this.onMintVariant,
    required this.accent,
    required this.secondary,
    required this.peach,
    required this.onPeach,
    required this.onPeachStrong,
    required this.amber,
    required this.onAmber,
    required this.error,
    required this.errorFill,
    required this.onErrorFill,
    required this.errorContainer,
    required this.escalationText,
    required this.escalationFill,
    required this.onEscalationFill,
    required this.escalationTitle,
    required this.escalationBody,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.logoTile,
    required this.thumbOff,
  });

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF7FAF7),
    card: Color(0xFFFFFFFF),
    surfaceLow: Color(0xFFF1F4F1),
    surface: Color(0xFFECEFEB),
    surfaceHigh: Color(0xFFE6E9E6),
    surfaceHighest: Color(0xFFE0E3E0),
    onSurface: Color(0xFF181C1B),
    onSurfaceVariant: Color(0xFF414944),
    outline: Color(0xFF717973),
    primary: Color(0xFF134230),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2D5A46),
    onPrimaryContainer: Color(0xFFFFFFFF),
    brand: Color(0xFF134230),
    brandContainer: Color(0xFF2D5A46),
    brandMuted: Color(0xFF3A6752),
    mint: Color(0xFFBCEED3),
    onMint: Color(0xFF002114),
    onMintVariant: Color(0xFF224F3C),
    accent: Color(0xFFFE932C),
    secondary: Color(0xFF904D00),
    peach: Color(0xFFFFDCC3),
    onPeach: Color(0xFF6E3900),
    onPeachStrong: Color(0xFF2F1500),
    amber: Color(0xFFFFB77D),
    onAmber: Color(0xFF2F1500),
    error: Color(0xFFBA1A1A),
    errorFill: Color(0xFFBA1A1A),
    onErrorFill: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD8),
    escalationText: Color(0xFF5B2E2D),
    escalationFill: Color(0xFF5B2E2D),
    onEscalationFill: Color(0xFFFFFFFF),
    escalationTitle: Color(0xFF340F10),
    escalationBody: Color(0xFF693938),
    inverseSurface: Color(0xFF181C1B),
    onInverseSurface: Color(0xFFFFFFFF),
    logoTile: Color(0xFFFFFFFF),
    thumbOff: Color(0xFFFFFFFF),
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0E1411),
    card: Color(0xFF161D19),
    surfaceLow: Color(0xFF1B231F),
    surface: Color(0xFF222B26),
    surfaceHigh: Color(0xFF2A342F),
    surfaceHighest: Color(0xFF333E38),
    onSurface: Color(0xFFE0E6E1),
    onSurfaceVariant: Color(0xFFB4BEB7),
    outline: Color(0xFF8B968F),
    primary: Color(0xFF2F7D5B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF2D7454),
    onPrimaryContainer: Color(0xFFFFFFFF),
    brand: Color(0xFF8FD9B0),
    brandContainer: Color(0xFF7CC79F),
    brandMuted: Color(0xFF86BFA0),
    mint: Color(0xFF1F4A38),
    onMint: Color(0xFFC6F2DB),
    onMintVariant: Color(0xFFA9E0C4),
    accent: Color(0xFFFE932C),
    secondary: Color(0xFFFFB77D),
    peach: Color(0xFF4B2F17),
    onPeach: Color(0xFFFFD3B0),
    onPeachStrong: Color(0xFFFFE1CB),
    amber: Color(0xFFFFB77D),
    onAmber: Color(0xFF2F1500),
    error: Color(0xFFFFB4AB),
    errorFill: Color(0xFFA8332F),
    onErrorFill: Color(0xFFFFFFFF),
    errorContainer: Color(0xFF4A1F1D),
    escalationText: Color(0xFFFFB4AB),
    escalationFill: Color(0xFF8C3B37),
    onEscalationFill: Color(0xFFFFFFFF),
    escalationTitle: Color(0xFFFFDAD8),
    escalationBody: Color(0xFFF2B8B5),
    inverseSurface: Color(0xFFE0E6E1),
    onInverseSurface: Color(0xFF0E1411),
    logoTile: Color(0xFFFFFFFF),
    thumbOff: Color(0xFF8B968F),
  );

  final Brightness brightness;

  // Surfaces
  final Color background;
  final Color card;
  final Color surfaceLow;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;

  // Content
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;

  // Brand fills (carry `on…` content)
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  // Brand as text / icon / border on a surface
  final Color brand;
  final Color brandContainer;
  final Color brandMuted;

  // Mint tint
  final Color mint;
  final Color onMint;
  final Color onMintVariant;

  // Warm accents
  final Color accent;
  final Color secondary;
  final Color peach;
  final Color onPeach;
  final Color onPeachStrong;
  final Color amber;
  final Color onAmber;

  // Error and escalation
  final Color error;
  final Color errorFill;
  final Color onErrorFill;
  final Color errorContainer;
  final Color escalationText;
  final Color escalationFill;
  final Color onEscalationFill;
  final Color escalationTitle;
  final Color escalationBody;

  // Misc
  final Color inverseSurface;
  final Color onInverseSurface;

  /// Brand-mark tile: always white so the two-colour logo keeps its contrast.
  final Color logoTile;

  /// Switch thumb when off.
  final Color thumbOff;

  bool get isDark => brightness == Brightness.dark;

  /// Colour for an icon [tone] (see `AppIcons.darkTones`).
  Color forTone(IconTone tone) => switch (tone) {
    IconTone.onSurface => onSurface,
    IconTone.onSurfaceVariant => onSurfaceVariant,
    IconTone.outline => outline,
    IconTone.brand => brand,
    IconTone.brandMuted => brandMuted,
    IconTone.onMint => onMint,
    IconTone.secondary => secondary,
    IconTone.error => error,
    IconTone.escalationText => escalationText,
  };

  /// Palettes are two fixed, immutable value sets; they are replaced wholesale.
  @override
  AppPalette copyWith() => this;

  /// Colours switch at the midpoint; the theme cross-fade is not worth
  /// interpolating 40 tokens for.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      other is AppPalette && t >= 0.5 ? other : this;
}

extension AppPaletteContext on BuildContext {
  /// The active palette. Falls back to light outside an app theme (e.g. a bare
  /// `MaterialApp` in a widget test).
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
