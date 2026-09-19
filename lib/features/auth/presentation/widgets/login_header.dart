import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// Logo mark, "Welcome back to Relay" and the tagline.
class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _LogoMark(),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'Welcome back to Relay',
            textAlign: TextAlign.center,
            style: AppTypography.titleAuth,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Stress-free approvals and decision memos at your fingertips.',
            textAlign: TextAlign.center,
            style: context.text.body18,
          ),
        ),
      ],
    );
  }
}

/// 80pt white tile with the brand mark and a soft, rotated mint shadow-plate.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // A 76pt square rotated -6deg fits the 83.5pt bounding box in the
            // design; it sits behind the 80pt tile so only its corners peek out.
            Positioned(
              left: 2,
              top: 2,
              width: 76,
              height: 76,
              child: Transform.rotate(
                angle: -6 * math.pi / 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.palette.mint.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(AppRadii.r24),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.logoTile,
                  borderRadius: BorderRadius.circular(AppRadii.r24),
                  boxShadow: AppShadows.level1,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: SvgAsset(AppIcons.logoMark, width: 56, height: 56),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
