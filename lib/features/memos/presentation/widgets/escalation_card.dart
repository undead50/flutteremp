import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

/// The red "PRIORITY ESCALATION" banner at the top of the feed.
class EscalationCard extends StatelessWidget {
  const EscalationCard({
    super.key,
    required this.escalation,
    required this.now,
    required this.onSignOff,
  });

  final MemoEscalation escalation;
  final DateTime now;
  final VoidCallback onSignOff;

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      color: context.palette.errorContainer,
      shadows: AppShadows.escalation,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SvgAsset(AppIcons.feedPriority, width: 3, height: 13.5),
                  const SizedBox(width: 6),
                  Text(
                    'PRIORITY ESCALATION',
                    style: AppTypography.overline.copyWith(color: context.palette.escalationText),
                  ),
                ],
              ),
              Text(
                Formatters.expiresIn(escalation.expiresAt, now),
                style: AppTypography.caption.copyWith(color: context.palette.escalationText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            escalation.title,
            style: AppTypography.label16.copyWith(color: context.palette.escalationTitle),
          ),
          const SizedBox(height: 4),
          Text(
            escalation.summary,
            style: context.text.body15.copyWith(color: context.palette.escalationBody),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.palette.escalationFill,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        escalation.ownerBadge,
                        style: AppTypography.captionRegular.copyWith(
                          color: context.palette.onEscalationFill,
                          fontSize: 10,
                          height: 1,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        escalation.ownerName,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: context.palette.escalationTitle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                excludeSemantics: true,
                label: 'Immediate sign-off: ${escalation.title}',
                onTap: onSignOff,
                child: Material(
                  color: context.palette.escalationFill,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  child: InkWell(
                    onTap: onSignOff,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        'Immediate Sign-off',
                        style: AppTypography.caption.copyWith(
                          color: context.palette.onEscalationFill,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
