import 'package:flutter/foundation.dart';

enum MemoCategory { budget, leave, policy }

/// Tone of a status badge; the UI maps tones to colours.
enum BadgeTone { attention, positive }

enum AttachmentKind { budget, document, schedule }

enum HighlightKind { verified, teamsImpacted, estimatedCost }

/// Filter chips above the feed. [all] is the "Memos" chip.
enum FeedFilter {
  all(null),
  budgets(MemoCategory.budget),
  leave(MemoCategory.leave),
  policies(MemoCategory.policy);

  const FeedFilter(this.category);

  final MemoCategory? category;

  bool matches(MemoSummary memo) => category == null || memo.category == category;
}

@immutable
final class MemoPerson {
  const MemoPerson({required this.name, this.title = '', this.department = '', this.avatar});

  final String name;

  /// e.g. `Staff Systems Architect`.
  final String title;

  /// e.g. `Core Infrastructure`.
  final String department;

  /// `asset:<path>` (mock) or https URL.
  final String? avatar;
}

@immutable
final class MemoBadge {
  const MemoBadge({required this.label, required this.tone});

  final String label;
  final BadgeTone tone;
}

@immutable
final class MemoAttachment {
  const MemoAttachment({required this.name, required this.kind, this.sizeBytes});

  final String name;
  final AttachmentKind kind;
  final int? sizeBytes;
}

@immutable
final class MemoHighlight {
  const MemoHighlight({required this.label, required this.kind});

  final String label;
  final HighlightKind kind;
}

/// One card in the "Pending Decision Feed".
@immutable
final class MemoSummary {
  const MemoSummary({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.submitter,
    required this.submittedAt,
    required this.badge,
    required this.category,
    this.attachments = const <MemoAttachment>[],
    this.highlights = const <MemoHighlight>[],
  });

  final String id;
  final String title;
  final String excerpt;
  final MemoPerson submitter;
  final DateTime submittedAt;
  final MemoBadge badge;
  final MemoCategory category;
  final List<MemoAttachment> attachments;
  final List<MemoHighlight> highlights;
}

/// The red "Priority Escalation" banner.
@immutable
final class MemoEscalation {
  const MemoEscalation({
    required this.memoId,
    required this.title,
    required this.summary,
    required this.expiresAt,
    required this.ownerName,
    required this.ownerBadge,
  });

  final String memoId;
  final String title;
  final String summary;
  final DateTime expiresAt;

  /// e.g. `Marcus Vance (Ops)`.
  final String ownerName;

  /// Short role tag shown in the avatar bubble, e.g. `VP`.
  final String ownerBadge;
}

/// Everything the home screen needs in one payload.
@immutable
final class MemoFeed {
  const MemoFeed({
    required this.criticalCount,
    required this.deadline,
    required this.items,
    required this.approvedThisMonth,
    this.escalation,
  });

  /// How many memos need sign-off before [deadline].
  final int criticalCount;
  final DateTime deadline;
  final MemoEscalation? escalation;
  final List<MemoSummary> items;
  final int approvedThisMonth;

  /// Chip counters, derived from [items] so they can never disagree with the list.
  int countFor(FeedFilter filter) => items.where(filter.matches).length;

  /// The feed after [memoId] was approved/declined elsewhere in the app.
  MemoFeed withoutMemo(String memoId, {required bool approved}) {
    final remaining = items.where((m) => m.id != memoId).toList(growable: false);
    final removedFromFeed = remaining.length != items.length;
    final removedEscalation = escalation?.memoId == memoId;
    return MemoFeed(
      criticalCount: removedFromFeed && criticalCount > 0 ? criticalCount - 1 : criticalCount,
      deadline: deadline,
      escalation: removedEscalation ? null : escalation,
      items: remaining,
      approvedThisMonth: approved && (removedFromFeed || removedEscalation)
          ? approvedThisMonth + 1
          : approvedThisMonth,
    );
  }
}
