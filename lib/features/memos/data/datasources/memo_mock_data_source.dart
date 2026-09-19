import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/features/memos/data/datasources/memo_remote_data_source.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

/// In-memory stand-in for the memo API (dev builds with `USE_MOCK_BACKEND=true`
/// and tests). Its content mirrors the Figma screens. State lives for the app
/// session, so approving a memo removes it from later feed loads.
final class MemoMockDataSource implements MemoRemoteDataSource {
  MemoMockDataSource({
    required DateTime Function() clock,
    this.latency = const Duration(milliseconds: 600),
  }) : _clock = clock;

  final DateTime Function() _clock;
  final Duration latency;

  final Set<String> _decided = <String>{};
  final Set<String> _seenKeys = <String>{};
  int _approvedByUser = 0;

  static String _avatar(String path) => '${AppImages.assetScheme}$path';

  Future<void> _delay() => Future<void>.delayed(latency);

  List<MemoSummary> _summaries(DateTime now) => <MemoSummary>[
    MemoSummary(
      id: 'hardware-q3',
      title: 'Q3 Hardware & Tooling Request',
      excerpt:
          'Requesting procurement of specialized high-performance workstations for the ML '
          'compiler team to accelerate neural cache builds.',
      submitter: MemoPerson(
        name: 'Maya Lin',
        department: 'Engineering Platform',
        avatar: _avatar(AppImages.avatarMaya),
      ),
      submittedAt: now.subtract(const Duration(minutes: 45, seconds: 5)),
      badge: const MemoBadge(label: 'Needs Approval', tone: BadgeTone.attention),
      category: MemoCategory.budget,
      attachments: const <MemoAttachment>[
        MemoAttachment(
          name: 'Tooling_CapEx_Budget.pdf',
          kind: AttachmentKind.budget,
          sizeBytes: 2516582,
        ),
      ],
      highlights: const <MemoHighlight>[
        MemoHighlight(label: 'Finance Pre-vetted', kind: HighlightKind.verified),
      ],
    ),
    MemoSummary(
      id: 'hybrid-workplace',
      title: 'Hybrid Workplace Guidelines 2025',
      excerpt:
          'Standardizing flexible collaboration hubs across EMEA and Americas. Clarifies '
          'monthly stipends and regional core anchor hours.',
      submitter: MemoPerson(
        name: 'Julian Sorel',
        department: 'People & Workplace',
        avatar: _avatar(AppImages.avatarJulian),
      ),
      submittedAt: now.subtract(const Duration(hours: 2, seconds: 5)),
      badge: const MemoBadge(label: 'Policy Update', tone: BadgeTone.positive),
      category: MemoCategory.policy,
      attachments: const <MemoAttachment>[
        MemoAttachment(name: 'Workplace_Principles_v3.docx', kind: AttachmentKind.document),
      ],
      highlights: const <MemoHighlight>[
        MemoHighlight(label: '4 Teams Impacted', kind: HighlightKind.teamsImpacted),
      ],
    ),
    MemoSummary(
      id: 'design-offsite',
      title: 'Design System Offsite Proposal',
      excerpt:
          '3-day collaborative workshop focused on token unification and micro-interaction '
          'libraries. Includes travel logistics breakdown.',
      submitter: MemoPerson(
        name: 'Kareena Patel',
        department: 'Experience Design',
        avatar: _avatar(AppImages.avatarKareena),
      ),
      submittedAt: now.subtract(const Duration(hours: 4, seconds: 5)),
      badge: const MemoBadge(label: 'Action Required', tone: BadgeTone.attention),
      category: MemoCategory.policy,
      attachments: const <MemoAttachment>[
        MemoAttachment(name: 'Offsite_Schedule_Kyoto.pdf', kind: AttachmentKind.schedule),
      ],
      highlights: const <MemoHighlight>[
        MemoHighlight(label: r'$14,200 Est.', kind: HighlightKind.estimatedCost),
      ],
    ),
  ];

  MemoEscalation _escalation(DateTime now) => MemoEscalation(
    memoId: 'fy25-cloud',
    title: 'FY25 Cloud Infrastructure Allocation',
    summary:
        'Cross-regional compute budget needs approval before automated capacity downsizing at EOD.',
    expiresAt: now.add(const Duration(hours: 2)),
    ownerName: 'Marcus Vance (Ops)',
    ownerBadge: 'VP',
  );

  @override
  Future<MemoFeed> fetchFeed() async {
    await _delay();
    final now = _clock();
    final items = _summaries(now).where((m) => !_decided.contains(m.id)).toList(growable: false);
    final escalation = _decided.contains('fy25-cloud') ? null : _escalation(now);
    return MemoFeed(
      criticalCount: items.length,
      deadline: DateTime(now.year, now.month, now.day, 14),
      escalation: escalation,
      items: items,
      approvedThisMonth: 18 + _approvedByUser,
    );
  }

  @override
  Future<MemoDetail> fetchMemo(String id) async {
    await _delay();
    final now = _clock();
    if (id == 'hardware-q3') return _hardwareDetail(now);
    if (id == 'fy25-cloud') {
      final e = _escalation(now);
      return _generic(
        id: e.memoId,
        title: e.title,
        summary: e.summary,
        author: MemoPerson(
          name: e.ownerName.replaceAll(' (Ops)', ''),
          title: 'VP Operations',
          department: 'Operations',
        ),
        submittedAt: now.subtract(const Duration(hours: 1)),
        urgent: true,
      );
    }
    for (final s in _summaries(now)) {
      if (s.id == id) {
        return _generic(
          id: s.id,
          title: s.title,
          summary: s.excerpt,
          author: s.submitter,
          submittedAt: s.submittedAt,
          urgent: s.badge.tone == BadgeTone.attention,
        );
      }
    }
    throw const AppException(NotFoundFailure());
  }

  @override
  Future<void> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) async {
    await _delay();
    // A replayed request (same key) is a no-op, exactly like a real backend.
    if (!_seenKeys.add(idempotencyKey)) return;
    if (_decided.add(memoId) && decision == ApprovalDecision.approve) _approvedByUser++;
  }

  MemoDetail _generic({
    required String id,
    required String title,
    required String summary,
    required MemoPerson author,
    required DateTime submittedAt,
    required bool urgent,
  }) {
    return MemoDetail(
      id: id,
      reference: id.toUpperCase(),
      title: title,
      isUrgent: urgent,
      reviewMinutes: 2,
      submittedAt: submittedAt,
      author: author,
      stages: <ApprovalStage>[
        ApprovalStage(
          title: 'Submitted for Review',
          description: '${author.name} submitted this memo',
          state: ApprovalStageState.done,
          completedAt: submittedAt,
        ),
        const ApprovalStage(
          title: 'Elena Vance (You)',
          description: 'Executive sign-off',
          state: ApprovalStageState.current,
        ),
      ],
      summary: summary,
    );
  }

  MemoDetail _hardwareDetail(DateTime now) {
    return MemoDetail(
      id: 'hardware-q3',
      reference: 'ENG-2024-098',
      title: 'Q3 Hardware & Tooling Request',
      isUrgent: true,
      reviewMinutes: 2,
      submittedAt: now.subtract(const Duration(hours: 2)),
      author: MemoPerson(
        name: 'Marcus Vance',
        title: 'Staff Systems Architect',
        department: 'Core Infrastructure',
        avatar: _avatar(AppImages.avatarMarcus),
      ),
      stages: <ApprovalStage>[
        ApprovalStage(
          title: 'Submitted for Review',
          description: 'Marcus Vance verified inventory deficit',
          state: ApprovalStageState.done,
          completedAt: DateTime(now.year, now.month, now.day, 9, 14),
        ),
        const ApprovalStage(
          title: 'Elena Vance (You)',
          description: 'Department Lead sign-off & resource validation',
          state: ApprovalStageState.current,
        ),
        const ApprovalStage(
          title: 'Finance Sign-off',
          description: 'Amara Okafor • Corporate Treasury allocation',
          state: ApprovalStageState.upcoming,
          stageLabel: 'Stage 3',
        ),
      ],
      summary:
          'Our core platform cluster is experiencing sustained compile bottlenecks on local dev '
          'environments. This proposal equips the five lead infrastructure engineers with dedicated '
          'Apple Silicon neural test benches and upgraded high-speed hardware keys to maintain '
          'release parity ahead of our targeted October rollout.',
      justification: const MemoJustification(
        body:
            'Engineers currently lose an estimated 42 minutes per business day to serialized build '
            'latency and cold container spinning. Accelerating our localized testing cycles '
            'mitigates critical runtime regressions, lowering cloud CI burst compute overages by an '
            'estimated 18% month-over-month.',
        metrics: <MemoMetric>[
          MemoMetric(
            label: 'Daily Time Saved',
            value: '3.5 hrs',
            caption: 'Across 5 staff engineers',
          ),
          MemoMetric(
            label: 'CI Cloud Offset',
            value: r'-$1,240',
            caption: 'Projected Q3 savings',
            tone: MetricTone.caution,
          ),
        ],
      ),
      budget: const MemoBudget(
        poolLabel: 'Q3 Hardware Pool',
        lines: <BudgetLine>[
          BudgetLine(
            name: 'M3 Max Dedicated Workstations (x2)',
            description: 'Local cluster emulation & kernel mocks',
            amountCents: 360000,
          ),
          BudgetLine(
            name: 'YubiKey 5C NFC Multi-Protocol (x10)',
            description: 'Zero-trust cryptographic physical tokens',
            amountCents: 55000,
          ),
          BudgetLine(
            name: 'CalDigit TS4 Thunderbolt Docks (x2)',
            description: 'High-throughput bus diagnostics',
            amountCents: 70000,
          ),
        ],
      ),
      impact: MemoImpact(
        body:
            'Immediate relief from multi-threaded build throttling. Equipping engineers with '
            'dedicated cryptographic hardware additionally enforces enterprise SOC2 compliance '
            'mandates without disrupting existing developer terminal workflows.',
        beneficiaryAvatars: <String?>[
          _avatar(AppImages.avatarTeam1),
          _avatar(AppImages.avatarTeam2),
        ],
        additionalBeneficiaries: 3,
      ),
      signatureId: '#7F02-99B',
    );
  }
}
