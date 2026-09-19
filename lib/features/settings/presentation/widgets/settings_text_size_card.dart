import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/relay_segmented_control.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// "Text Size & Readability": preset selector and a live preview memo that
/// picks up the chosen scale immediately.
class SettingsTextSizeCard extends StatelessWidget {
  const SettingsTextSizeCard({super.key, required this.selected, required this.onSelected});

  final TextSizePreset selected;
  final ValueChanged<TextSizePreset> onSelected;

  static String labelOf(TextSizePreset preset) => switch (preset) {
    TextSizePreset.standard => 'Standard',
    TextSizePreset.large => 'Large',
    TextSizePreset.extraLarge => 'Extra Large',
  };

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: <Widget>[
        SettingsCardHeader(
          icon: SettingsIcons.textSize,
          title: 'Text Size & Readability',
          subtitle: 'Calibrated for handheld executive flow',
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 78),
            child: RelayPill(
              label: 'A11y Presets',
              maxLines: 2,
              background: context.palette.surface,
              foreground: context.palette.onSurfaceVariant,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ),
        RelaySegmentedControl<TextSizePreset>(
          values: TextSizePreset.values,
          selected: selected,
          labelOf: labelOf,
          onChanged: onSelected,
        ),
        const _LivePreview(),
      ],
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Live preview of the selected text size',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadii.r24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      'LIVE PREVIEW MEMO',
                      style: AppTypography.overline.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '2m ago',
                    style: AppTypography.caption.copyWith(color: context.palette.outline),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Q3 Logistics Expansion & Freight Optimization', style: AppTypography.label16),
              const SizedBox(height: 5),
              Text(
                'Review required for supply chain routing adjustments across European hubs. '
                'All safety and operational margins have passed automated sign-off.',
                style: context.text.bodyCard,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  const SvgAsset(AppIcons.detailVerifiedUser, width: 10.67, height: 13.33),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Verified Origin',
                      style: AppTypography.caption.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: AppTypography.caption.copyWith(color: context.palette.outline)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Signatures: 2 of 3',
                      style: AppTypography.caption.copyWith(
                        color: context.palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
