import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';

/// Pill/rounded action button used everywhere in the design.
///
/// * Defaults to the primary (brand fill + `onPrimary` label) style; pass
///   [background] and [foreground] for other variants, or use [RelayButton.tonal].
/// * [isLoading] shows a spinner, blocks further taps (prevents double submit)
///   and keeps the label so the button doesn't jump in size.
/// * A `null` [onPressed] renders the disabled state.
class RelayButton extends StatelessWidget {
  const RelayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.background,
    this.foreground,
    this.height = 56,
    this.radius = AppRadii.r16,
    this.shadows = AppShadows.none,
    this.textStyle,
    this.isLoading = false,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.gap = 8,
    this.semanticLabel,
  }) : _tonal = false;

  /// Neutral tonal button (secondary actions).
  const RelayButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.background,
    this.foreground,
    this.height = 56,
    this.radius = AppRadii.r16,
    this.shadows = AppShadows.none,
    this.textStyle,
    this.isLoading = false,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.gap = 8,
    this.semanticLabel,
  }) : _tonal = true;

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;

  /// Fill colour; defaults to `primary` (or `surfaceLow` for [RelayButton.tonal]).
  final Color? background;

  /// Label/spinner colour; defaults to `onPrimary` (or `onSurface` for tonal).
  final Color? foreground;
  final double height;
  final double radius;
  final List<BoxShadow> shadows;
  final TextStyle? textStyle;
  final bool isLoading;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final double gap;
  final String? semanticLabel;
  final bool _tonal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = background ?? (_tonal ? palette.surfaceLow : palette.primary);
    final content = foreground ?? (_tonal ? palette.onSurface : palette.onPrimary);
    final disabled = onPressed == null;
    final tappable = !disabled && !isLoading;
    final style = (textStyle ?? AppTypography.label16).copyWith(color: content);
    final shape = BorderRadius.circular(radius);

    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel ?? label,
      value: isLoading ? 'Loading' : null,
      excludeSemantics: true,
      onTap: tappable ? onPressed : null,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, borderRadius: shape, boxShadow: shadows),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: shape,
              onTap: tappable ? onPressed : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: height,
                  minWidth: expand ? double.infinity : 0,
                ),
                child: Padding(
                  padding: padding,
                  child: Center(
                    widthFactor: expand ? null : 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (isLoading)
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: content),
                          )
                        else
                          ?leading,
                        if (isLoading || leading != null) SizedBox(width: gap),
                        Flexible(
                          child: Text(label, style: style, textAlign: TextAlign.center),
                        ),
                        if (trailing != null) ...<Widget>[SizedBox(width: gap), trailing!],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
