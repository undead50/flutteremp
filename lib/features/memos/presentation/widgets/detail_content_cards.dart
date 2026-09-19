import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/dot_heading.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.spacing, required this.children});

  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RelayCard(
      radius: AppRadii.r32,
      padding: const EdgeInsets.all(28),
      shadows: AppShadows.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    );
  }
}

/// "● Executive Summary"
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      spacing: 12,
      children: <Widget>[
        DotHeading(text: 'Executive Summary', dotColor: context.palette.brand),
        Text(body, style: AppTypography.bodyReading),
      ],
    );
  }
}

/// "● Business Justification" with the key-metric mosaic.
class JustificationCard extends StatelessWidget {
  const JustificationCard({super.key, required this.justification});

  final MemoJustification justification;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      spacing: 20,
      children: <Widget>[
        DotHeading(text: 'Business Justification', dotColor: context.palette.brandMuted),
        Text(justification.body, style: AppTypography.bodyReading),
        if (justification.metrics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: <Widget>[
                  for (final metric in justification.metrics)
                    Expanded(child: _MetricTile(metric: metric)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final MemoMetric metric;

  @override
  Widget build(BuildContext context) {
    final valueColor = metric.tone == MetricTone.caution
        ? context.palette.secondary
        : context.palette.brand;
    return ColoredBox(
      color: context.palette.surfaceLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              metric.label,
              style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(metric.value, style: AppTypography.metric.copyWith(color: valueColor)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(metric.caption, style: context.text.body15),
            ),
          ],
        ),
      ),
    );
  }
}

/// "● Budget Allocation" ledger with a derived total.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget});

  final MemoBudget budget;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      spacing: 20,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: DotHeading(
                text: 'Budget Allocation',
                dotColor: context.palette.secondary,
                dotSize: 9,
              ),
            ),
            if (budget.poolLabel.isNotEmpty) ...<Widget>[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 100),
                child: Text(
                  budget.poolLabel,
                  style: AppTypography.label14.copyWith(color: context.palette.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
        Column(
          spacing: 6,
          children: <Widget>[for (final line in budget.lines) _LedgerRow(line: line)],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: <Widget>[
              Text('Total Requisition', style: AppTypography.stat20Tall),
              Text(
                Formatters.usd(budget.totalCents),
                style: AppTypography.metricBold.copyWith(color: context.palette.brand),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.line});

  final BudgetLine line;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.surfaceLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      line.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label14,
                    ),
                    Text(line.description, style: context.text.body15),
                  ],
                ),
              ),
            ),
            Text(Formatters.usd(line.amountCents, withCents: false), style: AppTypography.label16),
          ],
        ),
      ),
    );
  }
}

/// "● Team Impact" with the beneficiary avatar cluster.
class ImpactCard extends StatelessWidget {
  const ImpactCard({super.key, required this.impact});

  final MemoImpact impact;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      spacing: 20,
      children: <Widget>[
        DotHeading(text: 'Team Impact', dotColor: context.palette.brandContainer),
        Text(impact.body, style: AppTypography.bodyReading),
        if (impact.beneficiaryAvatars.isNotEmpty || impact.additionalBeneficiaries > 0)
          ColoredBox(
            color: context.palette.surfaceLow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Row(
                      children: <Widget>[
                        _AvatarStack(impact: impact),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Beneficiary Engineers',
                            style: AppTypography.caption.copyWith(
                              color: context.palette.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SvgAsset(AppIcons.detailVerifiedUser, width: 13.33, height: 16.67),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Overlapping 32pt avatars (-8pt overlap) followed by a "+N" bubble.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.impact});

  final MemoImpact impact;

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const step = 24.0;
    final avatars = impact.beneficiaryAvatars;
    final extra = impact.additionalBeneficiaries;
    final count = avatars.length + (extra > 0 ? 1 : 0);

    return SizedBox(
      width: count == 0 ? 0 : size + (count - 1) * step,
      height: size,
      child: Stack(
        children: <Widget>[
          for (var i = 0; i < avatars.length; i++)
            Positioned(
              left: i * step,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2),
                  ],
                ),
                child: RelayAvatar(source: avatars[i], name: 'Engineer', size: size),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: avatars.length * step,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.surfaceHighest,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '+$extra',
                  style: AppTypography.caption.copyWith(
                    color: context.palette.onSurfaceVariant,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "Cryptographically signed with Relay ID #7F02-99B"
class SignatureLine extends StatelessWidget {
  const SignatureLine({super.key, required this.signatureId});

  final String signatureId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SvgAsset(AppIcons.detailLock, width: 10.67, height: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Cryptographically signed with Relay ID $signatureId',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
