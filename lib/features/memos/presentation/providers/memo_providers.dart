import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/features/memos/data/datasources/memo_mock_data_source.dart';
import 'package:relay/features/memos/data/datasources/memo_remote_data_source.dart';
import 'package:relay/features/memos/data/repositories/memo_repository_impl.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';
import 'package:relay/features/memos/domain/repositories/memo_repository.dart';
import 'package:relay/features/memos/domain/usecases/memo_usecases.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';

// ── Data wiring ───────────────────────────────────────────────────────────

final Provider<MemoRemoteDataSource> memoRemoteDataSourceProvider = Provider<MemoRemoteDataSource>(
  (ref) => ref.watch(appConfigProvider).useMockBackend
      ? MemoMockDataSource(clock: ref.watch(clockProvider))
      : MemoRemoteDataSourceImpl(ref.watch(dioProvider)),
);

final Provider<MemoRepository> memoRepositoryProvider = Provider<MemoRepository>(
  (ref) => MemoRepositoryImpl(
    remote: ref.watch(memoRemoteDataSourceProvider),
    logger: ref.watch(loggerProvider),
  ),
);

final Provider<GetMemoFeed> getMemoFeedProvider = Provider<GetMemoFeed>(
  (ref) => GetMemoFeed(ref.watch(memoRepositoryProvider)),
);

final Provider<GetMemoDetail> getMemoDetailProvider = Provider<GetMemoDetail>(
  (ref) => GetMemoDetail(ref.watch(memoRepositoryProvider)),
);

final Provider<SubmitMemoDecision> submitMemoDecisionProvider = Provider<SubmitMemoDecision>(
  (ref) => SubmitMemoDecision(ref.watch(memoRepositoryProvider)),
);

/// Converts whatever an `AsyncValue` carries into a user-safe [Failure].
Failure failureOf(Object error) => error is AppException ? error.failure : const UnknownFailure();

// ── Feed ──────────────────────────────────────────────────────────────────

final AsyncNotifierProvider<MemoFeedController, MemoFeed> memoFeedControllerProvider =
    AsyncNotifierProvider.autoDispose<MemoFeedController, MemoFeed>(MemoFeedController.new);

class MemoFeedController extends AsyncNotifier<MemoFeed> {
  @override
  Future<MemoFeed> build() async => (await ref.watch(getMemoFeedProvider)()).getOrThrow();

  /// Pull-to-refresh. Keeps the current list on screen while reloading.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // The error state is rendered by the screen; nothing to rethrow here.
    }
  }

  /// Called after a decision succeeded so the card disappears immediately.
  void removeMemo(String memoId, {required bool approved}) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData<MemoFeed>(current.withoutMemo(memoId, approved: approved));
  }
}

// ── Filters (chips) ───────────────────────────────────────────────────────

extension FeedFilterModule on FeedFilter {
  /// The workspace module that owns this chip.
  WorkspaceModule get module => switch (this) {
    FeedFilter.all => WorkspaceModule.executiveMemos,
    FeedFilter.budgets => WorkspaceModule.expenseApprovals,
    FeedFilter.leave => WorkspaceModule.teamLeave,
    FeedFilter.policies => WorkspaceModule.policyRevisions,
  };
}

/// Chips the user has left enabled under Settings → Active Modules.
final Provider<List<FeedFilter>> visibleFiltersProvider = Provider.autoDispose<List<FeedFilter>>((
  ref,
) {
  final modules = ref.watch(preferencesControllerProvider.select((p) => p.activeModules));
  final visible = FeedFilter.values
      .where((f) => modules.contains(f.module))
      .toList(growable: false);
  // Preferences guarantee one active module; fall back defensively anyway.
  return visible.isEmpty ? const <FeedFilter>[FeedFilter.all] : visible;
});

final NotifierProvider<FeedFilterSelection, FeedFilter> feedFilterSelectionProvider =
    NotifierProvider.autoDispose<FeedFilterSelection, FeedFilter>(FeedFilterSelection.new);

class FeedFilterSelection extends Notifier<FeedFilter> {
  @override
  FeedFilter build() => FeedFilter.all;

  void select(FeedFilter filter) => state = filter;
}

/// The chip actually applied: the selected one, or the first visible chip if
/// the selected one was just switched off.
final Provider<FeedFilter> activeFilterProvider = Provider.autoDispose<FeedFilter>((ref) {
  final visible = ref.watch(visibleFiltersProvider);
  final selected = ref.watch(feedFilterSelectionProvider);
  return visible.contains(selected) ? selected : visible.first;
});

// ── Detail ────────────────────────────────────────────────────────────────

final memoDetailProvider = FutureProvider.autoDispose.family<MemoDetail, String>(
  (ref, id) async => (await ref.watch(getMemoDetailProvider)(id)).getOrThrow(),
);

// ── Decisions ─────────────────────────────────────────────────────────────

/// Ids of memos with a decision currently in flight. Buttons watch this to
/// show a spinner and ignore further taps (no double submit).
final NotifierProvider<MemoDecisionController, Set<String>> memoDecisionControllerProvider =
    NotifierProvider.autoDispose<MemoDecisionController, Set<String>>(MemoDecisionController.new);

class MemoDecisionController extends Notifier<Set<String>> {
  /// One idempotency key per (memo, decision) until it succeeds, so a retry
  /// after an ambiguous network failure can't be applied twice by the backend.
  final Map<String, String> _idempotencyKeys = <String, String>{};

  @override
  Set<String> build() => const <String>{};

  Future<Result<void>> decide({
    required String memoId,
    required ApprovalDecision decision,
    String? comment,
  }) async {
    if (state.contains(memoId)) return const Result<void>.failure(ConflictFailure());

    final link = ref.keepAlive();
    state = <String>{...state, memoId};
    try {
      final prefs = ref.read(preferencesControllerProvider);

      // Optional local step-up before signing. Friction only; the backend
      // remains the authority on whether the sign-off is accepted.
      if (decision == ApprovalDecision.approve && prefs.biometricRecheck) {
        final check = await ref
            .read(biometricAuthenticatorProvider)
            .authenticate(reason: 'Confirm your sign-off');
        if (check case Err<void>(:final failure)) return Result<void>.failure(failure);
      }

      final keyId = '$memoId:${decision.name}';
      final key = _idempotencyKeys.putIfAbsent(keyId, ref.read(idGeneratorProvider).next);
      final result = await ref.read(submitMemoDecisionProvider)(
        memoId: memoId,
        decision: decision,
        idempotencyKey: key,
        comment: comment,
      );

      if (result.isSuccess) {
        _idempotencyKeys.remove(keyId);
        if (ref.exists(memoFeedControllerProvider)) {
          ref
              .read(memoFeedControllerProvider.notifier)
              .removeMemo(memoId, approved: decision == ApprovalDecision.approve);
        }
        if (decision == ApprovalDecision.approve && prefs.hapticOnApproval) {
          await ref.read(hapticsProvider).success();
        }
      }
      return result;
    } finally {
      if (ref.mounted) state = <String>{...state}..remove(memoId);
      link.close();
    }
  }
}
