import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_theme.dart';

/// Elevated surface. Adds a visible border when the user turned on
/// "High Contrast Borders" in Settings.
class RelayCard extends StatelessWidget {
  const RelayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.r16,
    this.color,
    this.shadows = AppShadows.feedCard,
    this.clipBehavior = Clip.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Defaults to the palette's `card` surface (white in light mode).
  final Color? color;
  final List<BoxShadow> shadows;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final highContrast =
        Theme.of(context).extension<RelayAccessibilityTheme>()?.highContrast ?? false;
    return Container(
      clipBehavior: clipBehavior,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border: highContrast ? Border.all(color: palette.onSurfaceVariant, width: 1.5) : null,
      ),
      child: child,
    );
  }
}
