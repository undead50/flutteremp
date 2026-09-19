import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// "SOC2 Type II Protected · Live" trust strip.
class LoginTrustBadge extends StatelessWidget {
  const LoginTrustBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      color: context.palette.surfaceLow,
      shadows: AppShadows.none,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.palette.mint, shape: BoxShape.circle),
                  child: const SvgAsset(AppIcons.loginShieldCheck, width: 12, height: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('SOC2 Type II Protected', style: AppTypography.label14),
                      Text(
                        'Relay Encrypted Workspace',
                        style: AppTypography.caption.copyWith(color: context.palette.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RelayPill(
            label: 'Live',
            background: context.palette.surface,
            foreground: context.palette.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: const _Dot(),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.palette.brand, shape: BoxShape.circle),
      ),
    );
  }
}

/// "Locked out? Contact IT Operations" and build metadata.
class LoginSupportFooter extends StatelessWidget {
  const LoginSupportFooter({super.key, required this.onContactIt});

  final VoidCallback onContactIt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Semantics(
          button: true,
          excludeSemantics: true,
          label: 'Locked out? Contact IT Operations',
          onTap: onContactIt,
          child: InkWell(
            onTap: onContactIt,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SvgAsset(AppIcons.loginHeadset, width: 15, height: 13.5),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Locked out? Contact IT Operations',
                      textAlign: TextAlign.center,
                      style: AppTypography.label14.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Relay Desktop & Mobile v4.8 • Single Tenant Node',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: context.palette.outline),
          ),
        ),
      ],
    );
  }
}
