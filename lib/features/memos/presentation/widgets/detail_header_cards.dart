import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';

/// Urgency + review-time pills on the left, "2h ago" on the right.
class DetailPriorityRow extends StatelessWidget {
  const DetailPriorityRow({super.key, required this.memo, required this.now});

  final MemoDetail memo;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (memo.isUrgent)
                  RelayPill(
                    label: 'Urgent Priority',
                    background: context.palette.peach,
                    foreground: context.palette.onPeachStrong,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    gap: 4,
                    leading: SizedBox.square(
                      dimension: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.palette.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                RelayPill(
                  label: '${memo.reviewMinutes} min review',
                  background: context.palette.surfaceHigh,
                  foreground: context.palette.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: <Widget>[
              const SvgAsset(AppIcons.detailClock, width: 15, height: 15),
              const SizedBox(width: 4),
              Text(
                Formatters.relativeAgo(memo.submittedAt, now),
                style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Memo reference, title and author strip.
class DetailTitleCard extends StatelessWidget {
  const DetailTitleCard({super.key, required this.memo});

  final MemoDetail memo;

  @override
  Widget build(BuildContext context) {
    final role = <String>[
      if (memo.author.title.isNotEmpty) memo.author.title,
      if (memo.author.department.isNotEmpty) memo.author.department,
    ].join(' • ');

    return RelayCard(
      radius: AppRadii.r32,
      padding: const EdgeInsets.all(28),
      shadows: AppShadows.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 5.5),
            child: Text(
              'MEMO #${memo.reference}',
              style: AppTypography.overline.copyWith(color: context.palette.brandMuted),
            ),
          ),
          const SizedBox(height: 6),
          Semantics(header: true, child: Text(memo.title, style: AppTypography.titleDetail)),
          const SizedBox(height: 20),
          // Square corners are intentional: the design draws this strip unrounded.
          ColoredBox(
            color: context.palette.surfaceLow,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  RelayAvatar(source: memo.author.avatar, name: memo.author.name, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                memo.author.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            RelayPill(
                              label: 'Submitter',
                              background: context.palette.mint.withValues(alpha: 0.6),
                              foreground: context.palette.brand,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                          ],
                        ),
                        if (role.isNotEmpty) Text(role, style: context.text.body15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Approval Pathway" timeline with a connecting thread behind the steps.
class ApprovalPathwayCard extends StatelessWidget {
  const ApprovalPathwayCard({super.key, required this.memo});

  final MemoDetail memo;

  @override
  Widget build(BuildContext context) {
    final step = memo.stageNumber;
    return RelayCard(
      radius: AppRadii.r32,
      padding: const EdgeInsets.all(28),
      shadows: AppShadows.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text('Approval Pathway', style: AppTypography.headline),
                ),
              ),
              if (step != null) ...<Widget>[
                const SizedBox(width: 8),
                RelayPill(
                  label: 'Step $step of ${memo.stages.length}',
                  background: context.palette.mint.withValues(alpha: 0.3),
                  foreground: context.palette.brandMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: <Widget>[
              // Thread runs from the first to the last circle centre, behind the rows.
              Positioned(
                left: 19,
                top: 20,
                bottom: 20,
                width: 2,
                child: ColoredBox(color: context.palette.surfaceHigh),
              ),
              Column(
                spacing: 12,
                children: <Widget>[for (final stage in memo.stages) _StageRow(stage: stage)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage});

  final ApprovalStage stage;

  @override
  Widget build(BuildContext context) {
    return switch (stage.state) {
      ApprovalStageState.done => _row(
        context,
        circle: _circle(
          context.palette.brandContainer,
          AppIcons.detailStepDone,
          13.58,
          10.02,
          shadow: true,
        ),
        trailing: stage.completedAt == null
            ? null
            : Text(
                Formatters.timelineTime(stage.completedAt!),
                style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
              ),
        topPadding: 4,
      ),
      ApprovalStageState.current => ColoredBox(
        color: context.palette.surfaceLow,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _row(
            context,
            circle: _circle(
              context.palette.accent,
              AppIcons.detailStepPending,
              13.33,
              16.67,
              shadow: true,
            ),
            trailing: RelayPill(
              label: 'Pending',
              background: context.palette.peach,
              foreground: context.palette.onPeachStrong,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            topPadding: 0,
          ),
        ),
      ),
      ApprovalStageState.upcoming => Opacity(
        opacity: 0.6,
        child: _row(
          context,
          circle: _circle(context.palette.surfaceHighest, AppIcons.detailStepNext, 16.67, 16.67),
          trailing: stage.stageLabel == null
              ? null
              : Text(
                  stage.stageLabel!,
                  style: AppTypography.caption.copyWith(color: context.palette.outline),
                ),
          topPadding: 4,
          muted: true,
        ),
      ),
    };
  }

  Widget _circle(Color color, String icon, double w, double h, {bool shadow = false}) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: shadow ? AppShadows.level1 : null,
      ),
      child: SvgAsset(icon, width: w, height: h),
    );
  }

  Widget _row(
    BuildContext context, {
    required Widget circle,
    required Widget? trailing,
    required double topPadding,
    bool muted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        circle,
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(child: Text(stage.title, style: AppTypography.label14)),
                    if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing],
                  ],
                ),
                Text(
                  stage.description,
                  style: context.text.body15.copyWith(
                    color: muted ? context.palette.outline : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
