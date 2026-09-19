import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Frosted-glass bar (`backdrop-blur-[12px]` + translucent fill + shadow) used
/// by the header, bottom navigation and the sign-off drawer.
class BlurBar extends StatelessWidget {
  const BlurBar({
    super.key,
    required this.color,
    required this.shadows,
    required this.child,
    this.sigma = 12,
  });

  final Color color;
  final List<BoxShadow> shadows;
  final double sigma;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(boxShadow: shadows),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: ColoredBox(color: color, child: child),
        ),
      ),
    );
  }
}
