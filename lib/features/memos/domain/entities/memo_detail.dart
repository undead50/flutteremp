import 'package:flutter/foundation.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

enum ApprovalStageState { done, current, upcoming }

@immutable
final class ApprovalStage {
  const ApprovalStage({
    required this.title,
    required this.description,
    required this.state,
    this.completedAt,
    this.stageLabel,
  });

  final String title;
  final String description;
  final ApprovalStageState state;

  /// When a completed stage was signed off.
  final DateTime? completedAt;

  /// e.g. `Stage 3` for upcoming steps.
  final String? stageLabel;
}

enum MetricTone { positive, caution }

@immutable
final class MemoMetric {
  const MemoMetric({
    required this.label,
    required this.value,
    required this.caption,
    this.tone = MetricTone.positive,
  });

  final String label;
  final String value;
  final String caption;
  final MetricTone tone;
}

@immutable
final class MemoJustification {
  const MemoJustification({required this.body, this.metrics = const <MemoMetric>[]});

  final String body;
  final List<MemoMetric> metrics;
}

@immutable
final class BudgetLine {
  const BudgetLine({required this.name, required this.description, required this.amountCents});

  final String name;
  final String description;

  /// Integer cents: no floating point money.
  final int amountCents;
}

@immutable
final class MemoBudget {
  const MemoBudget({required this.poolLabel, required this.lines});

  final String poolLabel;
  final List<BudgetLine> lines;

  /// Always derived from the lines, so the total can't contradict them.
  int get totalCents => lines.fold<int>(0, (sum, line) => sum + line.amountCents);
}

@immutable
final class MemoImpact {
  const MemoImpact({
    required this.body,
    this.beneficiaryAvatars = const <String?>[],
    this.additionalBeneficiaries = 0,
  });

  final String body;
  final List<String?> beneficiaryAvatars;
  final int additionalBeneficiaries;
}

/// Full memo, as opened from the feed. Optional sections are simply omitted
/// by the API when they don't apply and are hidden by the UI.
@immutable
final class MemoDetail {
  const MemoDetail({
    required this.id,
    required this.reference,
    required this.title,
    required this.isUrgent,
    required this.reviewMinutes,
    required this.submittedAt,
    required this.author,
    required this.stages,
    required this.summary,
    this.justification,
    this.budget,
    this.impact,
    this.signatureId,
  });

  final String id;

  /// e.g. `ENG-2024-098`.
  final String reference;
  final String title;
  final bool isUrgent;
  final int reviewMinutes;
  final DateTime submittedAt;
  final MemoPerson author;
  final List<ApprovalStage> stages;
  final String summary;
  final MemoJustification? justification;
  final MemoBudget? budget;
  final MemoImpact? impact;

  /// e.g. `#7F02-99B`, shown as the cryptographic sign-off line.
  final String? signatureId;

  int? get stageNumber {
    final index = stages.indexWhere((s) => s.state == ApprovalStageState.current);
    return index == -1 ? null : index + 1;
  }
}
