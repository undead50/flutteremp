import 'package:flutter/widgets.dart';
import 'package:relay/core/theme/app_metrics.dart';

/// Centres [child] and caps its width at the design's 448pt column, so phones
/// use the full width while tablets and landscape get a phone-width column.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.maxContentWidth,
    this.alignment = Alignment.topCenter,
    this.shrinkHeight = false,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  /// Wrap the child's height instead of filling the parent. Required for bars
  /// (bottom nav, sign-off drawer) that sit in an unbounded-height slot.
  final bool shrinkHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      heightFactor: shrinkHeight ? 1 : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
