import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_toggles.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// "Active Modules": which feeds appear on the primary deck.
class SettingsModulesCard extends StatelessWidget {
  const SettingsModulesCard({super.key, required this.activeModules, required this.onToggle});

  final Set<WorkspaceModule> activeModules;
  final void Function(WorkspaceModule module, {required bool enabled}) onToggle;

  static ({IconData icon, String title, String subtitle}) describe(WorkspaceModule module) =>
      switch (module) {
        WorkspaceModule.executiveMemos => (
          icon: SettingsIcons.executiveMemos,
          title: 'Executive Memos',
          subtitle: 'High-priority leadership decisions',
        ),
        WorkspaceModule.expenseApprovals => (
          icon: SettingsIcons.expenses,
          title: 'Expense Approvals',
          subtitle: 'Team operational & travel budgets',
        ),
        WorkspaceModule.teamLeave => (
          icon: SettingsIcons.leave,
          title: 'Team Leave Schedule',
          subtitle: 'Absence requests & coverage maps',
        ),
        WorkspaceModule.policyRevisions => (
          icon: SettingsIcons.policies,
          title: 'Policy Revisions',
          subtitle: 'Quarterly compliance & legal shifts',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final total = WorkspaceModule.values.length;
    return SettingsSectionCard(
      children: <Widget>[
        SettingsCardHeader(
          icon: SettingsIcons.modules,
          title: 'Active Modules',
          subtitle: 'Toggle feeds appearing on primary deck',
          trailing: Text(
            '${activeModules.length} of $total Active',
            textAlign: TextAlign.right,
            style: AppTypography.caption.copyWith(color: context.palette.brand),
          ),
        ),
        Column(
          spacing: 8,
          children: <Widget>[
            for (final module in WorkspaceModule.values)
              _ModuleRow(
                module: module,
                enabled: activeModules.contains(module),
                onChanged: (value) => onToggle(module, enabled: value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module, required this.enabled, required this.onChanged});

  final WorkspaceModule module;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final info = SettingsModulesCard.describe(module);
    final shape = BorderRadius.circular(AppRadii.r20);
    return Semantics(
      container: true,
      checked: enabled,
      label: '${info.title}. ${info.subtitle}',
      onTap: () => onChanged(!enabled),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.palette.surfaceLow, borderRadius: shape),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: shape,
            onTap: () => onChanged(!enabled),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: <Widget>[
                  Icon(info.icon, size: 18, color: context.palette.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(info.title, style: AppTypography.label14),
                          Text(
                            info.subtitle,
                            style: AppTypography.caption.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  RelayCheckboxMark(value: enabled),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
