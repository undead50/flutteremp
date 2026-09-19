import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';

/// Rounded label used for badges, chips, counters and status tags.
class RelayPill extends StatelessWidget {
  const RelayPill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.leading,
    this.gap = 6,
    this.radius = AppRadii.pill,
    this.textStyle,
    this.maxLines = 1,
    this.trailingText,
    this.trailingTextColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final EdgeInsetsGeometry padding;
  final Widget? leading;
  final double gap;
  final double radius;
  final TextStyle? textStyle;
  final int maxLines;

  /// Optional lighter text after the label (e.g. a file size).
  final String? trailingText;
  final Color? trailingTextColor;

  @override
  Widget build(BuildContext context) {
    final style = (textStyle ?? AppTypography.caption).copyWith(color: foreground);
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (leading != null) ...<Widget>[leading!, SizedBox(width: gap)],
            Flexible(
              child: Text(label, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis),
            ),
            if (trailingText != null) ...<Widget>[
              SizedBox(width: gap),
              Text(
                trailingText!,
                style: AppTypography.captionRegular.copyWith(
                  color: trailingTextColor ?? context.palette.outline,
                ),
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
