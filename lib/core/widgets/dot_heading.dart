import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_typography.dart';

/// Section title preceded by a small colour dot ("● Executive Summary").
class DotHeading extends StatelessWidget {
  const DotHeading({super.key, required this.text, required this.dotColor, this.dotSize = 10});

  final String text;
  final Color dotColor;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ExcludeSemantics(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(header: true, child: Text(text, style: AppTypography.headline)),
        ),
      ],
    );
  }
}
