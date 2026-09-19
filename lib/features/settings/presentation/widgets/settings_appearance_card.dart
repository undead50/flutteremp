import 'package:flutter/material.dart';
import 'package:relay/core/widgets/relay_segmented_control.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// "Appearance": System / Light / Dark theme.
class SettingsAppearanceCard extends StatelessWidget {
  const SettingsAppearanceCard({super.key, required this.selected, required this.onSelected});

  final AppearanceMode selected;
  final ValueChanged<AppearanceMode> onSelected;

  static String labelOf(AppearanceMode mode) => switch (mode) {
    AppearanceMode.system => 'System',
    AppearanceMode.light => 'Light',
    AppearanceMode.dark => 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: <Widget>[
        const SettingsCardHeader(
          icon: SettingsIcons.appearance,
          title: 'Appearance',
          subtitle: 'Match your device or choose a theme',
        ),
        RelaySegmentedControl<AppearanceMode>(
          values: AppearanceMode.values,
          selected: selected,
          labelOf: labelOf,
          onChanged: onSelected,
        ),
      ],
    );
  }
}
