import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';

/// A bundled SVG icon. Decorative by default (hidden from screen readers);
/// pass [semanticLabel] when the icon carries meaning on its own.
class SvgAsset extends StatelessWidget {
  const SvgAsset(this.path, {super.key, this.width, this.height, this.color, this.semanticLabel});

  final String path;
  final double? width;
  final double? height;

  /// Recolours a single-colour glyph (used for selected/unselected states).
  /// When null, dark mode applies the icon's entry in `AppIcons.darkTones`.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tone = AppIcons.darkTones[path];
    final tint = color ?? (palette.isDark && tone != null ? palette.forTone(tone) : null);
    return SvgPicture.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
