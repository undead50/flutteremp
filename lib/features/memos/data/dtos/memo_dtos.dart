import 'package:relay/core/error/failure.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/core/security/https_url.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

/// Parses untrusted memo JSON into domain entities.
///
/// Rules: required fields must be present with the right type; text is
/// sanitised and length-limited; lists are size-capped; avatar URLs must be
/// https; unknown *optional* enum values are skipped instead of failing the
/// whole screen (forward compatibility).
abstract final class MemoDtos {
  static MemoFeed feed(JsonObject json) {
    final escalation = json.optObject('escalation');
    return MemoFeed(
      criticalCount: json.integer('criticalCount', max: 10000),
      deadline: json.dateTime('deadline'),
      approvedThisMonth: json.integer('approvedThisMonth', max: 1000000),
      escalation: escalation == null ? null : _escalation(escalation),
      items: json.objects('items', maxItems: 100).map(_summary).toList(growable: false),
    );
  }

  static MemoDetail detail(JsonObject json) {
    final summary = json.optParagraph('summary', maxLength: 6000);
    if (summary == null || summary.isEmpty) throw const MalformedResponseException('summary');

    final justification = json.optObject('justification');
    final budget = json.optObject('budget');
    final impact = json.optObject('impact');

    return MemoDetail(
      id: json.string('id', maxLength: 64),
      reference: json.string('reference', maxLength: 40),
      title: json.string('title', maxLength: 160),
      isUrgent: json.boolean('isUrgent', fallback: false),
      reviewMinutes: json.integer('reviewMinutes', min: 1, max: 600),
      submittedAt: json.dateTime('submittedAt'),
      author: _person(json.object('author')),
      stages: json.objects('stages', maxItems: 12).map(_stage).toList(growable: false),
      summary: summary,
      justification: justification == null ? null : _justification(justification),
      budget: budget == null ? null : _budget(budget),
      impact: impact == null ? null : _impact(impact),
      signatureId: json.optString('signatureId', maxLength: 40),
    );
  }

  // ── pieces ──────────────────────────────────────────────────────────────

  static MemoPerson _person(JsonObject json) => MemoPerson(
    name: json.string('name', maxLength: 80),
    title: json.optString('title', maxLength: 80) ?? '',
    department: json.optString('department', maxLength: 80) ?? '',
    avatar: parseHttpsImageUrl(json.optString('avatarUrl', maxLength: 2048))?.toString(),
  );

  static MemoSummary _summary(JsonObject json) => MemoSummary(
    id: json.string('id', maxLength: 64),
    title: json.string('title', maxLength: 160),
    excerpt: json.optString('excerpt', maxLength: 400) ?? '',
    submitter: _person(json.object('submitter')),
    submittedAt: json.dateTime('submittedAt'),
    category: json.enumValue('category', MemoCategory.values),
    badge: MemoBadge(
      label: json.object('badge').string('label', maxLength: 40),
      tone: json.object('badge').enumValue('tone', BadgeTone.values, fallback: BadgeTone.attention),
    ),
    attachments: _skippingUnknown(json.optObjects('attachments', maxItems: 10), _attachment),
    highlights: _skippingUnknown(json.optObjects('highlights', maxItems: 10), _highlight),
  );

  static MemoAttachment _attachment(JsonObject json) => MemoAttachment(
    name: json.string('name', maxLength: 120),
    kind: json.enumValue('kind', AttachmentKind.values),
    sizeBytes: json.optInt('sizeBytes', max: 1 << 34),
  );

  static MemoHighlight _highlight(JsonObject json) => MemoHighlight(
    label: json.string('label', maxLength: 60),
    kind: json.enumValue('kind', HighlightKind.values),
  );

  static MemoEscalation _escalation(JsonObject json) => MemoEscalation(
    memoId: json.string('memoId', maxLength: 64),
    title: json.string('title', maxLength: 160),
    summary: json.optString('summary', maxLength: 400) ?? '',
    expiresAt: json.dateTime('expiresAt'),
    ownerName: json.string('ownerName', maxLength: 80),
    ownerBadge: json.optString('ownerBadge', maxLength: 6) ?? '',
  );

  static ApprovalStage _stage(JsonObject json) => ApprovalStage(
    title: json.string('title', maxLength: 80),
    description: json.optString('description', maxLength: 200) ?? '',
    state: json.enumValue('state', ApprovalStageState.values),
    completedAt: json.optDateTime('completedAt')?.toLocal(),
    stageLabel: json.optString('stageLabel', maxLength: 24),
  );

  static MemoJustification _justification(JsonObject json) => MemoJustification(
    body: json.optParagraph('body', maxLength: 4000) ?? '',
    metrics: json.optObjects('metrics', maxItems: 4).map(_metric).toList(growable: false),
  );

  static MemoMetric _metric(JsonObject json) => MemoMetric(
    label: json.string('label', maxLength: 40),
    value: json.string('value', maxLength: 24),
    caption: json.optString('caption', maxLength: 60) ?? '',
    tone: json.enumValue('tone', MetricTone.values, fallback: MetricTone.positive),
  );

  static MemoBudget _budget(JsonObject json) => MemoBudget(
    poolLabel: json.optString('poolLabel', maxLength: 60) ?? '',
    lines: json
        .objects('lines', maxItems: 50)
        .map(
          (line) => BudgetLine(
            name: line.string('name', maxLength: 120),
            description: line.optString('description', maxLength: 160) ?? '',
            // Money is integer cents on the wire; floats are rejected.
            amountCents: line.integer('amountCents', min: -100000000000, max: 100000000000),
          ),
        )
        .toList(growable: false),
  );

  static MemoImpact _impact(JsonObject json) => MemoImpact(
    body: json.optParagraph('body', maxLength: 4000) ?? '',
    beneficiaryAvatars: json
        .optObjects('beneficiaries', maxItems: 8)
        .map((b) => parseHttpsImageUrl(b.optString('avatarUrl', maxLength: 2048))?.toString())
        .toList(growable: false),
    additionalBeneficiaries: json.optInt('additionalBeneficiaries', max: 100000) ?? 0,
  );

  static List<T> _skippingUnknown<T>(List<JsonObject> items, T Function(JsonObject) parse) {
    final out = <T>[];
    for (final item in items) {
      try {
        out.add(parse(item));
      } on MalformedResponseException {
        continue;
      }
    }
    return List<T>.unmodifiable(out);
  }
}
