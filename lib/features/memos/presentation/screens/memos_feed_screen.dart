import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_headers.dart';
import 'package:relay/core/widgets/relay_snackbar.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/state_views.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';
import 'package:relay/features/memos/presentation/providers/memo_decision_flow.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';
import 'package:relay/features/memos/presentation/widgets/approved_archive_tile.dart';
import 'package:relay/features/memos/presentation/widgets/escalation_card.dart';
import 'package:relay/features/memos/presentation/widgets/feed_filter_chips.dart';
import 'package:relay/features/memos/presentation/widgets/feed_greeting.dart';
import 'package:relay/features/memos/presentation/widgets/memo_feed_card.dart';

/// Home tab: daily briefing, filters, escalation and the pending decision feed.
class MemosFeedScreen extends ConsumerWidget {
  const MemosFeedScreen({super.key});

  /// Toasts on tab screens float above the 80pt bottom navigation.
  static const double toastInset = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(memoFeedControllerProvider);
    final user = ref.watch(currentUserProvider);
    final topInset = MediaQuery.viewPaddingOf(context).top + AppLayout.headerHeight;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: feed.when(
              data: (data) => _FeedContent(feed: data, topInset: topInset),
              loading: () => Padding(
                padding: EdgeInsets.only(top: topInset),
                child: const LoadingView(label: 'Loading memos'),
              ),
              error: (error, _) => Padding(
                padding: EdgeInsets.only(top: topInset),
                child: ErrorView(
                  failure: failureOf(error),
                  onRetry: () => ref.invalidate(memoFeedControllerProvider),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RelayBrandHeader(
              title: 'Memos',
              avatarSource: user?.avatar,
              userName: user?.displayName ?? '',
              onSearch: () => RelaySnackbar.show(
                context,
                'Search is not available yet.',
                bottomInset: toastInset,
              ),
              onProfile: () => context.go(RoutePaths.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedContent extends ConsumerWidget {
  const _FeedContent({required this.feed, required this.topInset});

  final MemoFeed feed;
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final now = ref.watch(clockProvider)();
    final filters = ref.watch(visibleFiltersProvider);
    final active = ref.watch(activeFilterProvider);
    final approving = ref.watch(memoDecisionControllerProvider);
    final visible = feed.items.where(active.matches).toList(growable: false);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom + AppLayout.navHeight + 32;

    return RefreshIndicator(
      color: context.palette.brand,
      backgroundColor: context.palette.card,
      edgeOffset: topInset,
      onRefresh: ref.read(memoFeedControllerProvider.notifier).refresh,
      child: ResponsiveBody(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(child: SizedBox(height: topInset)),
            SliverToBoxAdapter(
              child: FeedGreeting(
                firstName: user?.firstName ?? '',
                now: now,
                criticalCount: feed.criticalCount,
                deadline: feed.deadline,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FeedFilterChips(
                  filters: filters,
                  selected: active,
                  countOf: feed.countFor,
                  onSelected: ref.read(feedFilterSelectionProvider.notifier).select,
                ),
              ),
            ),
            if (feed.escalation case final escalation?)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: EscalationCard(
                    escalation: escalation,
                    now: now,
                    onSignOff: () => context.push(RoutePaths.memoDetail(escalation.memoId)),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: _FeedHeading()),
            if (visible.isEmpty)
              SliverToBoxAdapter(
                child: feed.items.isEmpty
                    ? const EmptyView(
                        icon: Icons.task_alt_rounded,
                        title: "You're all caught up",
                        message:
                            'No memos are waiting for your decision. New requests appear here.',
                      )
                    : const EmptyView(
                        icon: Icons.filter_list_off_rounded,
                        title: 'Nothing in this view',
                        message: 'No pending memos match this filter right now.',
                      ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final memo = visible[index];
                    return MemoFeedCard(
                      key: ValueKey<String>(memo.id),
                      memo: memo,
                      now: now,
                      isApproving: approving.contains(memo.id),
                      onReview: () => context.push(RoutePaths.memoDetail(memo.id)),
                      onQuickApprove: () => MemoDecisionFlow.approve(
                        context,
                        ref,
                        memoId: memo.id,
                        title: memo.title,
                        toastInset: MemosFeedScreen.toastInset,
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: ApprovedArchiveTile(
                count: feed.approvedThisMonth,
                onOpen: () => context.go(RoutePaths.activity),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: bottomInset - 20)),
          ],
        ),
      ),
    );
  }
}

class _FeedHeading extends StatelessWidget {
  const _FeedHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text('Pending Decision Feed', style: AppTypography.headline),
          ),
          Text(
            'Swipe to batch',
            style: AppTypography.label14.copyWith(color: context.palette.brand),
          ),
        ],
      ),
    );
  }
}
