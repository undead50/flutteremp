import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_toggles.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// "Tactile & Contrast": haptics, high-contrast borders, biometric re-check.
class SettingsTactileCard extends StatelessWidget {
  const SettingsTactileCard({
    super.key,
    required this.preferences,
    required this.onHaptic,
    required this.onHighContrast,
    required this.onBiometric,
  });

  final UserPreferences preferences;
  final ValueChanged<bool> onHaptic;
  final ValueChanged<bool> onHighContrast;
  final ValueChanged<bool> onBiometric;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: <Widget>[
        SettingsCardHeader(
          icon: SettingsIcons.tactile,
          title: 'Tactile & Contrast',
          subtitle: 'Physical feedback during high-stakes reviews',
          iconBackground: context.palette.peach,
          iconForeground: context.palette.secondary,
        ),
        _SwitchRow(
          icon: SettingsIcons.haptic,
          iconColor: context.palette.onSurfaceVariant,
          title: 'Haptic on Approval',
          subtitle: 'Subtle pulse confirmation on approval',
          value: preferences.hapticOnApproval,
          onChanged: onHaptic,
        ),
        _SwitchRow(
          icon: SettingsIcons.contrast,
          iconColor: context.palette.secondary,
          title: 'High Contrast Borders',
          subtitle: 'Sharpen boundaries for sunlight',
          value: preferences.highContrast,
          onChanged: onHighContrast,
        ),
        _SwitchRow(
          icon: SettingsIcons.biometric,
          iconColor: context.palette.accent,
          title: 'Biometric Re-check',
          subtitle: 'FaceID before final signature',
          value: preferences.biometricRecheck,
          onChanged: onBiometric,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadii.r28);
    return Semantics(
      container: true,
      toggled: value,
      label: '$title. $subtitle',
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.palette.surfaceLow, borderRadius: shape),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: shape,
            onTap: () => onChanged(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                child: Row(
                  children: <Widget>[
                    IconBadge(
                      icon: icon,
                      background: context.palette.card,
                      foreground: iconColor,
                      size: 32,
                      iconSize: 16,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(title, style: AppTypography.label14),
                          Text(
                            subtitle,
                            style: AppTypography.caption.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RelaySwitchTrack(value: value),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
