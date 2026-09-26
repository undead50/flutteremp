import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_pill.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

/// One pending memo in the "Pending Decision Feed".
class MemoFeedCard extends StatelessWidget {
  const MemoFeedCard({
    super.key,
    required this.memo,
    required this.now,
    required this.isApproving,
    required this.onQuickApprove,
    required this.onReview,
  });

  final MemoSummary memo;
  final DateTime now;

  /// A decision for this memo is in flight: disable both actions.
  final bool isApproving;
  final VoidCallback onQuickApprove;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    RelayAvatar(source: memo.submitter.avatar, name: memo.submitter.name, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(memo.submitter.name, style: AppTypography.label14),
                          Text(
                            '${memo.submitter.department} • ${Formatters.relativeAgo(memo.submittedAt, now)}',
                            style: AppTypography.caption.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(badge: memo.badge),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(header: true, child: Text(memo.title, style: AppTypography.label16)),
          const SizedBox(height: 5),
          Text(memo.excerpt, style: context.text.bodyCard),
          if (memo.attachments.isNotEmpty || memo.highlights.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: <Widget>[
                for (final attachment in memo.attachments) _AttachmentChip(attachment: attachment),
                for (final highlight in memo.highlights) _HighlightChip(highlight: highlight),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: RelayButton(
                  label: 'Quick Approve',
                  height: 44,
                  radius: AppRadii.pill,
                  gap: 6,
                  background: context.palette.primaryContainer,
                  shadows: AppShadows.approveGlow,
                  textStyle: AppTypography.label14,
                  isLoading: isApproving,
                  semanticLabel: 'Quick approve ${memo.title}',
                  onPressed: isApproving ? null : onQuickApprove,
                  leading: const SvgAsset(AppIcons.feedApprove, width: 15, height: 15),
                ),
              ),
              const SizedBox(width: 10),
              RelayButton.tonal(
                label: 'Review',
                height: 44,
                radius: AppRadii.pill,
                gap: 6,
                expand: false,
                background: context.palette.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                textStyle: AppTypography.label14,
                semanticLabel: 'Review ${memo.title}',
                onPressed: isApproving ? null : onReview,
                leading: const SvgAsset(AppIcons.feedReview, width: 16.5, height: 11.25),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.badge});

  final MemoBadge badge;

  @override
  Widget build(BuildContext context) {
    final positive = badge.tone == BadgeTone.positive;
    return ConstrainedBox(
      // Narrow on purpose: two-word badges wrap onto two lines as in the design.
      constraints: const BoxConstraints(maxWidth: 88),
      child: RelayPill(
        label: badge.label,
        maxLines: 2,
        background: positive ? context.palette.mint : context.palette.peach,
        foreground: positive ? context.palette.onMintVariant : context.palette.onPeach,
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment});

  final MemoAttachment attachment;

  (String, double, double) get _icon => switch (attachment.kind) {
    AttachmentKind.budget => (AppIcons.feedAttachBudget, 13.33, 8.33),
    AttachmentKind.document => (AppIcons.feedAttachDocument, 12, 15),
    AttachmentKind.schedule => (AppIcons.feedAttachSchedule, 15, 15),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, w, h) = _icon;
    return RelayPill(
      label: attachment.name,
      background: context.palette.surface,
      foreground: context.palette.onSurfaceVariant,
      radius: AppRadii.r32,
      leading: SvgAsset(icon, width: w, height: h),
      trailingText: attachment.sizeBytes == null
          ? null
          : Formatters.fileSize(attachment.sizeBytes!),
      trailingTextColor: context.palette.outline,
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({required this.highlight});

  final MemoHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final (icon, w, h, background, foreground) = switch (highlight.kind) {
      HighlightKind.verified => (
        AppIcons.feedVerified,
        14.67,
        14.0,
        context.palette.mint,
        context.palette.onMint,
      ),
      HighlightKind.teamsImpacted => (
        AppIcons.feedTeams,
        16.0,
        8.0,
        context.palette.surface,
        context.palette.onSurfaceVariant,
      ),
      HighlightKind.estimatedCost => (
        AppIcons.feedEstimate,
        13.33,
        12.67,
        context.palette.amber,
        context.palette.onAmber,
      ),
    };
    return RelayPill(
      label: highlight.label,
      background: background,
      foreground: foreground,
      radius: AppRadii.r32,
      leading: SvgAsset(icon, width: w, height: h),
    );
  }
}
