import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';

/// Type scale from the Figma file. Two families, both bundled as variable fonts:
/// Epilogue for headings/metrics and Plus Jakarta Sans for everything else.
///
/// `height` is `lineHeight / fontSize`; `leadingDistribution.even` reproduces
/// CSS half-leading so multi-line blocks sit exactly where they do in the design.
///
/// These styles deliberately carry **no colour**: text inherits the theme's
/// `onSurface` from the enclosing `Material`, and call sites that need another
/// role pass `.copyWith(color: context.palette.…)`. Styles whose default in the
/// design is the *secondary* text colour live in [AppTextStyles] instead.
abstract final class AppTypography {
  static const String _epilogue = 'Epilogue';
  static const String _jakarta = 'PlusJakartaSans';

  static TextStyle _style({
    required String family,
    required double size,
    required double lineHeight,
    required int weight,
    double tracking = 0,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      // Variable fonts: pin the weight axis explicitly so every platform agrees.
      fontVariations: <FontVariation>[FontVariation('wght', weight.toDouble())],
      letterSpacing: tracking,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextStyle _ep(double size, double line, double tracking, [int weight = 600]) =>
      _style(family: _epilogue, size: size, lineHeight: line, weight: weight, tracking: tracking);

  static TextStyle _pj(double size, double line, {int weight = 400, double tracking = 0}) =>
      _style(family: _jakarta, size: size, lineHeight: line, weight: weight, tracking: tracking);

  // ── Epilogue ────────────────────────────────────────────────────────────
  static final TextStyle titleAuth = _ep(26, 34, -0.65); // "Welcome back to Relay"
  // The welcome hero renders at regular weight in the design (CSS `font-normal`).
  static final TextStyle titleHeroLight = _ep(24, 30, -0.6, 400);
  static final TextStyle headlineGreeting = _ep(22, 30, -0.55); // "Good morning, Elena"
  static final TextStyle headline = _ep(22, 30, -0.22); // section titles, app bar title
  static final TextStyle titleDetail = _ep(26, 35.75, -0.39); // memo title
  static final TextStyle metric = _ep(26, 34, -0.39);
  static final TextStyle metricBold = _ep(26, 34, -0.39, 700);
  static final TextStyle cardTitle = _ep(20, 28, -0.2); // settings card titles

  // ── Plus Jakarta Sans ───────────────────────────────────────────────────
  static final TextStyle label16 = _pj(16, 22, weight: 600, tracking: 0.16);
  static final TextStyle label14 = _pj(14, 20, weight: 600, tracking: 0.28);
  static final TextStyle caption = _pj(12, 16, weight: 600, tracking: 0.36);
  static final TextStyle captionRegular = _pj(12, 16, tracking: 0.36);
  static final TextStyle overline = _pj(12, 16, weight: 600, tracking: 0.6);
  static final TextStyle counter = _pj(11, 20, weight: 600, tracking: 0.28);
  static final TextStyle stat20 = _pj(20, 25, weight: 600);
  static final TextStyle stat20Tall = _pj(20, 28, weight: 600);
  static final TextStyle bodyReading = _pj(18, 29.25);
  static final TextStyle input = _pj(18, 23);

  /// Default (regular 15/22) text style for the app theme's `TextTheme`.
  static final TextStyle base = _pj(15, 22);

  // Secondary-colour body styles: see [AppTextStyles].
  static final TextStyle _body15 = base;
  static final TextStyle _bodyCard = _pj(15, 24.38);
  static final TextStyle _body17 = _pj(17, 27.63);
  static final TextStyle _body18 = _pj(18, 28);
}

/// Body styles that default to the *secondary* text colour, resolved against the
/// active palette (`context.text.body15`).
class AppTextStyles {
  const AppTextStyles._(this._palette);

  final AppPalette _palette;

  TextStyle get body15 => AppTypography._body15.copyWith(color: _palette.onSurfaceVariant);
  TextStyle get bodyCard => AppTypography._bodyCard.copyWith(color: _palette.onSurfaceVariant);
  TextStyle get body17 => AppTypography._body17.copyWith(color: _palette.onSurfaceVariant);
  TextStyle get body18 => AppTypography._body18.copyWith(color: _palette.onSurfaceVariant);
}

extension AppTextStylesContext on BuildContext {
  AppTextStyles get text => AppTextStyles._(palette);
}
