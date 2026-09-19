import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// Photo, name, role, level/ID chips and the "Active Reviewer" strip.
class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({super.key, required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final role = <String>[
      if (user.title.isNotEmpty) user.title,
      if (user.department.isNotEmpty) user.department,
    ].join(' · ');

    return SettingsSectionCard(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _AvatarWithBadge(user: user),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(user.displayName, style: AppTypography.cardTitle),
                  ),
                  if (role.isNotEmpty) Text(role, style: context.text.body15),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      if (user.level.isNotEmpty)
                        RelayPill(
                          label: user.level,
                          background: context.palette.mint,
                          foreground: context.palette.onMintVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        ),
                      if (user.employeeCode.isNotEmpty)
                        RelayPill(
                          label: 'ID: ${user.employeeCode}',
                          background: context.palette.surfaceHigh,
                          foreground: context.palette.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.surfaceLow,
            borderRadius: BorderRadius.circular(AppRadii.r16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 8,
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: context.palette.brand, shape: BoxShape.circle),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.signedMemoCount > 0
                        ? 'Active Reviewer (${user.signedMemoCount} memos signed)'
                        : 'Reviewer',
                    style: AppTypography.label14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(SettingsIcons.reviewerCheck, size: 17, color: context.palette.brandContainer),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          RelayAvatar(
            source: user.avatar,
            name: user.displayName,
            size: 64,
            semanticLabel: 'Profile photo of ${user.displayName}',
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: ExcludeSemantics(
              child: Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.palette.card, width: 1.5),
                  boxShadow: AppShadows.level1,
                ),
                child: Icon(
                  SettingsIcons.check,
                  size: 12,
                  color: context.palette.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
