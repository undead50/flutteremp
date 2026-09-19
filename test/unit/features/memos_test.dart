import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/features/memos/data/dtos/memo_dtos.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';
import 'package:relay/features/memos/domain/repositories/memo_repository.dart';
import 'package:relay/features/memos/domain/usecases/memo_usecases.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';

import '../../helpers/test_harness.dart';

class _RecordingMemoRepository implements MemoRepository {
  final List<({String id, ApprovalDecision decision, String? comment, String key})> submitted =
      <({String id, ApprovalDecision decision, String? comment, String key})>[];
  final List<String> requestedDetails = <String>[];

  @override
  Future<Result<MemoFeed>> getFeed() async => throw UnimplementedError();

  @override
  Future<Result<MemoDetail>> getMemo(String id) async {
    requestedDetails.add(id);
    return const Result<MemoDetail>.failure(NotFoundFailure());
  }

  @override
  Future<Result<void>> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) async {
    submitted.add((id: memoId, decision: decision, comment: comment, key: idempotencyKey));
    return const Result<void>.success(null);
  }
}

Map<String, Object?> _feedJson() => <String, Object?>{
  'criticalCount': 2,
  'deadline': '2023-10-24T14:00:00Z',
  'approvedThisMonth': 18,
  'escalation': <String, Object?>{
    'memoId': 'fy25',
    'title': 'Cloud',
    'expiresAt': '2023-10-24T12:00:00Z',
    'ownerName': 'Marcus',
    'ownerBadge': 'VP',
  },
  'items': <Object?>[
    <String, Object?>{
      'id': 'm1',
      'title': 'Hardware',
      'excerpt': 'Buy laptops',
      'category': 'budget',
      'submittedAt': '2023-10-24T08:56:00Z',
      'badge': <String, Object?>{'label': 'Needs Approval', 'tone': 'attention'},
      'submitter': <String, Object?>{'name': 'Maya Lin', 'avatarUrl': 'http://evil.example/a.png'},
      'attachments': <Object?>[
        <String, Object?>{'name': 'a.pdf', 'kind': 'budget', 'sizeBytes': 100},
        <String, Object?>{'name': 'b.bin', 'kind': 'hologram'},
      ],
      'highlights': <Object?>[
        <String, Object?>{'label': '4 Teams', 'kind': 'teamsImpacted'},
        <String, Object?>{'label': '???', 'kind': 'from-the-future'},
      ],
    },
  ],
};

void main() {
  group('SubmitMemoDecision (use case)', () {
    late _RecordingMemoRepository repo;
    late SubmitMemoDecision useCase;

    setUp(() {
      repo = _RecordingMemoRepository();
      useCase = SubmitMemoDecision(repo);
    });

    test('approve needs no note and sends none', () async {
      final result = await useCase(
        memoId: 'm1',
        decision: ApprovalDecision.approve,
        idempotencyKey: 'k1',
        comment: 'ignored?',
      );
      expect(result.isSuccess, isTrue);
      expect(repo.submitted.single.comment, isNull, reason: 'an approval never carries a note');
    });

    test('revision and decline are refused without a proper note', () async {
      for (final decision in <ApprovalDecision>[
        ApprovalDecision.requestRevision,
        ApprovalDecision.decline,
      ]) {
        for (final note in <String?>[null, '', '  ', 'ab']) {
          final result = await useCase(
            memoId: 'm1',
            decision: decision,
            idempotencyKey: 'k',
            comment: note,
          );
          expect(result.failureOrNull, isA<ValidationFailure>(), reason: '$decision/$note');
        }
      }
      expect(repo.submitted, isEmpty);
    });

    test('notes are sanitised before they are sent', () async {
      final zeroWidth = String.fromCharCode(0x200B);
      await useCase(
        memoId: 'm1',
        decision: ApprovalDecision.decline,
        idempotencyKey: 'k',
        comment: '  Over${zeroWidth}budget  \n\n\n\n please revise ',
      );
      expect(repo.submitted.single.comment, 'Overbudget \n\n please revise');
    });

    test('unsafe memo ids are rejected before any request is built', () async {
      for (final id in <String>['../admin', 'a b', '', 'x' * 65, 'id?admin=true']) {
        final result = await useCase(
          memoId: id,
          decision: ApprovalDecision.approve,
          idempotencyKey: 'k',
        );
        expect(result.failureOrNull, isA<NotFoundFailure>(), reason: id);
      }
      expect(repo.submitted, isEmpty);
    });

    test('GetMemoDetail applies the same id allow-list', () async {
      final get = GetMemoDetail(repo);
      expect((await get('../../etc/passwd')).failureOrNull, isA<NotFoundFailure>());
      expect(repo.requestedDetails, isEmpty);
      await get('hardware-q3');
      expect(repo.requestedDetails, <String>['hardware-q3']);
    });
  });

  group('MemoDtos.feed', () {
    test('parses a valid payload, skipping unknown optional enum values', () {
      final feed = MemoDtos.feed(JsonObject(_feedJson()));
      expect(feed.criticalCount, 2);
      expect(feed.escalation?.memoId, 'fy25');
      final memo = feed.items.single;
      expect(memo.category, MemoCategory.budget);
      expect(memo.attachments.map((a) => a.name), <String>['a.pdf']);
      expect(memo.highlights.map((h) => h.label), <String>['4 Teams']);
    });

    test('drops non-https avatar URLs', () {
      final feed = MemoDtos.feed(JsonObject(_feedJson()));
      expect(feed.items.single.submitter.avatar, isNull);
    });

    test('a missing required field fails the whole payload', () {
      final json = _feedJson()..remove('deadline');
      expect(() => MemoDtos.feed(JsonObject(json)), throwsA(isA<MalformedResponseException>()));
    });

    test('an unknown required enum (category) fails the payload', () {
      final json = _feedJson();
      ((json['items']! as List<Object?>).single! as Map<String, Object?>)['category'] = 'weather';
      expect(() => MemoDtos.feed(JsonObject(json)), throwsA(isA<MalformedResponseException>()));
    });

    test('an oversized list is refused', () {
      final json = _feedJson();
      final item = (json['items']! as List<Object?>).single;
      json['items'] = List<Object?>.filled(101, item);
      expect(() => MemoDtos.feed(JsonObject(json)), throwsA(isA<MalformedResponseException>()));
    });
  });

  group('MemoDtos.detail', () {
    Map<String, Object?> detailJson({Object? amount = 360000}) => <String, Object?>{
      'id': 'm1',
      'reference': 'ENG-1',
      'title': 'Hardware',
      'reviewMinutes': 2,
      'submittedAt': '2023-10-24T08:00:00Z',
      'author': <String, Object?>{'name': 'Marcus'},
      'stages': <Object?>[
        <String, Object?>{'title': 'Submitted', 'state': 'done'},
        <String, Object?>{'title': 'You', 'state': 'current'},
      ],
      'summary': 'Short summary',
      'budget': <String, Object?>{
        'poolLabel': 'Pool',
        'lines': <Object?>[
          <String, Object?>{'name': 'A', 'amountCents': amount},
          <String, Object?>{'name': 'B', 'amountCents': 55000},
        ],
      },
    };

    test('parses and derives the total from the lines', () {
      final memo = MemoDtos.detail(JsonObject(detailJson()));
      expect(memo.budget?.totalCents, 415000);
      expect(memo.stageNumber, 2);
      expect(memo.isUrgent, isFalse);
      expect(memo.justification, isNull);
    });

    test('money must be integer cents: floats and strings are rejected', () {
      for (final bad in <Object>[3600.5, '3600', -1e15]) {
        expect(
          () => MemoDtos.detail(JsonObject(detailJson(amount: bad))),
          throwsA(isA<MalformedResponseException>()),
          reason: '$bad',
        );
      }
    });

    test('an empty summary is malformed', () {
      final json = detailJson()..['summary'] = '   ';
      expect(() => MemoDtos.detail(JsonObject(json)), throwsA(isA<MalformedResponseException>()));
    });
  });

  group('MemoFeed', () {
    final feed = MemoFeed(
      criticalCount: 3,
      deadline: DateTime(2023, 10, 24, 14),
      approvedThisMonth: 18,
      escalation: MemoEscalation(
        memoId: 'esc',
        title: 't',
        summary: 's',
        expiresAt: DateTime(2023, 10, 24, 12),
        ownerName: 'o',
        ownerBadge: 'VP',
      ),
      items: <MemoSummary>[
        for (final (id, category) in <(String, MemoCategory)>[
          ('a', MemoCategory.budget),
          ('b', MemoCategory.policy),
          ('c', MemoCategory.policy),
        ])
          MemoSummary(
            id: id,
            title: id,
            excerpt: '',
            submitter: const MemoPerson(name: 'x'),
            submittedAt: DateTime(2023),
            badge: const MemoBadge(label: 'b', tone: BadgeTone.attention),
            category: category,
          ),
      ],
    );

    test('chip counts are derived from the items', () {
      expect(feed.countFor(FeedFilter.all), 3);
      expect(feed.countFor(FeedFilter.budgets), 1);
      expect(feed.countFor(FeedFilter.leave), 0);
      expect(feed.countFor(FeedFilter.policies), 2);
    });

    test('approving removes the memo and updates the counters', () {
      final after = feed.withoutMemo('b', approved: true);
      expect(after.items.map((m) => m.id), <String>['a', 'c']);
      expect(after.criticalCount, 2);
      expect(after.approvedThisMonth, 19);
    });

    test('declining removes the memo without counting it as approved', () {
      final after = feed.withoutMemo('a', approved: false);
      expect(after.criticalCount, 2);
      expect(after.approvedThisMonth, 18);
    });

    test('removing the escalated memo clears the banner', () {
      final after = feed.withoutMemo('esc', approved: true);
      expect(after.escalation, isNull);
      expect(after.items, hasLength(3));
      expect(after.approvedThisMonth, 19);
    });

    test('removing an unknown id changes nothing', () {
      final after = feed.withoutMemo('zzz', approved: true);
      expect(after.items, hasLength(3));
      expect(after.criticalCount, 3);
      expect(after.approvedThisMonth, 18);
    });
  });

  group('MemoFeedController / MemoDecisionController', () {
    test('loads the feed from the (mock) backend', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container();
      final feed = await container.read(memoFeedControllerProvider.future);
      expect(feed.items.map((m) => m.id), <String>[
        'hardware-q3',
        'hybrid-workplace',
        'design-offsite',
      ]);
      expect(feed.countFor(FeedFilter.policies), 2);
    });

    test('a backend failure becomes an error state carrying a safe failure', () async {
      final harness = await TestHarness.create(signedIn: true);
      harness.memoSource.feedFailure = const NetworkFailure();
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});

      await expectLater(
        container.read(memoFeedControllerProvider.future),
        throwsA(isA<AppException>()),
      );
      final state = container.read(memoFeedControllerProvider);
      expect(state.hasError, isTrue);
      expect(failureOf(state.error!), isA<NetworkFailure>());
    });

    test('an approve removes the card, buzzes, and re-checks biometrics first', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);

      final result = await container
          .read(memoDecisionControllerProvider.notifier)
          .decide(memoId: 'hardware-q3', decision: ApprovalDecision.approve);

      expect(result.isSuccess, isTrue);
      expect(harness.biometrics.reasons, hasLength(1));
      expect(harness.haptics.successCount, 1);
      final feed = container.read(memoFeedControllerProvider).requireValue;
      expect(feed.items.map((m) => m.id), isNot(contains('hardware-q3')));
      expect(feed.approvedThisMonth, 19);
    });

    test('a failed biometric check aborts before anything is sent', () async {
      final harness = await TestHarness.create(signedIn: true);
      harness.biometrics.outcome = const Result<void>.failure(BiometricCancelledFailure());
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);

      final result = await container
          .read(memoDecisionControllerProvider.notifier)
          .decide(memoId: 'hardware-q3', decision: ApprovalDecision.approve);

      expect(result.failureOrNull, isA<BiometricCancelledFailure>());
      expect(harness.memoSource.decisions, isEmpty);
      expect(harness.haptics.successCount, 0);
      expect(container.read(memoFeedControllerProvider).requireValue.items, hasLength(3));
    });

    test('the biometric re-check can be switched off in Settings', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);
      await container
          .read(preferencesControllerProvider.notifier)
          .setBiometricRecheck(enabled: false);
      await container
          .read(preferencesControllerProvider.notifier)
          .setHapticOnApproval(enabled: false);

      await container
          .read(memoDecisionControllerProvider.notifier)
          .decide(memoId: 'hardware-q3', decision: ApprovalDecision.approve);

      expect(harness.biometrics.reasons, isEmpty);
      expect(harness.haptics.successCount, 0);
      expect(harness.memoSource.decisions, hasLength(1));
    });

    test('a retry after a network failure reuses the same idempotency key', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);
      final controller = container.read(memoDecisionControllerProvider.notifier);

      harness.memoSource.decisionFailure = const TimeoutFailure();
      final first = await controller.decide(
        memoId: 'hardware-q3',
        decision: ApprovalDecision.approve,
      );
      expect(first.failureOrNull, isA<TimeoutFailure>());

      harness.memoSource.decisionFailure = null;
      final second = await controller.decide(
        memoId: 'hardware-q3',
        decision: ApprovalDecision.approve,
      );
      expect(second.isSuccess, isTrue);

      final keys = harness.memoSource.decisions.map((d) => d.key).toList();
      expect(keys, hasLength(2));
      expect(keys[0], keys[1]);

      // A different memo gets a fresh key.
      await controller.decide(memoId: 'hybrid-workplace', decision: ApprovalDecision.approve);
      expect(harness.memoSource.decisions.last.key, isNot(keys[0]));
    });

    test('a second tap while a decision is in flight is refused (no double submit)', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);
      final controller = container.read(memoDecisionControllerProvider.notifier);

      final inFlight = controller.decide(memoId: 'hardware-q3', decision: ApprovalDecision.approve);
      expect(container.read(memoDecisionControllerProvider), contains('hardware-q3'));
      final duplicate = await controller.decide(
        memoId: 'hardware-q3',
        decision: ApprovalDecision.approve,
      );
      await inFlight;

      expect(duplicate.failureOrNull, isA<ConflictFailure>());
      expect(harness.memoSource.decisions, hasLength(1));
      expect(container.read(memoDecisionControllerProvider), isEmpty);
    });

    test('decline needs a note and sends it once provided', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()..listen(memoFeedControllerProvider, (_, _) {});
      await container.read(memoFeedControllerProvider.future);
      final controller = container.read(memoDecisionControllerProvider.notifier);

      final refused = await controller.decide(
        memoId: 'hardware-q3',
        decision: ApprovalDecision.decline,
      );
      expect(refused.failureOrNull, isA<ValidationFailure>());
      expect(harness.memoSource.decisions, isEmpty);

      final accepted = await controller.decide(
        memoId: 'hardware-q3',
        decision: ApprovalDecision.decline,
        comment: 'Budget exceeded for Q3',
      );
      expect(accepted.isSuccess, isTrue);
      expect(harness.memoSource.decisions.single.comment, 'Budget exceeded for Q3');
      expect(harness.biometrics.reasons, isEmpty, reason: 'step-up applies to approvals only');
    });
  });

  group('Feed filters and Active Modules', () {
    test('all four chips are visible by default', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container();
      expect(container.read(visibleFiltersProvider), FeedFilter.values);
      expect(container.read(activeFilterProvider), FeedFilter.all);
    });

    test('switching a module off hides its chip and falls back if it was selected', () async {
      final harness = await TestHarness.create(signedIn: true);
      final container = harness.container()
        ..listen(feedFilterSelectionProvider, (_, _) {})
        ..listen(activeFilterProvider, (_, _) {});
      container.read(feedFilterSelectionProvider.notifier).select(FeedFilter.budgets);
      expect(container.read(activeFilterProvider), FeedFilter.budgets);

      final failure = await container
          .read(preferencesControllerProvider.notifier)
          .setModule(WorkspaceModule.expenseApprovals, enabled: false);

      expect(failure, isNull);
      expect(container.read(visibleFiltersProvider), isNot(contains(FeedFilter.budgets)));
      expect(container.read(activeFilterProvider), FeedFilter.all);
    });
  });
}
