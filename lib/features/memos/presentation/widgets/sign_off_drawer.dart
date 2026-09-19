import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/blur_bar.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// Sticky bottom console: one big thumb-reachable Approve, plus Revise/Decline.
class SignOffDrawer extends StatelessWidget {
  const SignOffDrawer({
    super.key,
    required this.approveLabel,
    required this.isBusy,
    required this.onApprove,
    required this.onRequestRevision,
    required this.onDecline,
  });

  final String approveLabel;

  /// A decision is being submitted: show progress on Approve, disable all.
  final bool isBusy;
  final VoidCallback onApprove;
  final VoidCallback onRequestRevision;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return BlurBar(
      color: context.palette.card.withValues(alpha: 0.95),
      shadows: AppShadows.bottomDrawer,
      child: SafeArea(
        top: false,
        child: ResponsiveBody(
          shrinkHeight: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                RelayButton(
                  label: approveLabel,
                  height: 54,
                  radius: AppRadii.pill,
                  gap: 6,
                  shadows: AppShadows.primaryButton,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : onApprove,
                  leading: const SvgAsset(AppIcons.detailApprove, width: 18.33, height: 18.33),
                ),
                Row(
                  spacing: 6,
                  children: <Widget>[
                    Expanded(
                      child: RelayButton.tonal(
                        label: 'Request Revision',
                        height: 48,
                        radius: AppRadii.pill,
                        gap: 6,
                        background: context.palette.surfaceHigh,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: AppTypography.label14,
                        onPressed: isBusy ? null : onRequestRevision,
                        leading: const SvgAsset(AppIcons.detailRevision, width: 13.5, height: 12),
                      ),
                    ),
                    Expanded(
                      child: RelayButton.tonal(
                        label: 'Decline Feedback',
                        height: 48,
                        radius: AppRadii.pill,
                        gap: 6,
                        background: context.palette.surface,
                        foreground: context.palette.error,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: AppTypography.label14,
                        onPressed: isBusy ? null : onDecline,
                        leading: const SvgAsset(AppIcons.detailDecline, width: 10.5, height: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
