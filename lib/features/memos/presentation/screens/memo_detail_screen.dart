import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:relay/app/router/route_paths.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/relay_headers.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/state_views.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/presentation/providers/memo_decision_flow.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';
import 'package:relay/features/memos/presentation/widgets/detail_content_cards.dart';
import 'package:relay/features/memos/presentation/widgets/detail_header_cards.dart';
import 'package:relay/features/memos/presentation/widgets/sign_off_drawer.dart';

/// Full memo with the approval pathway and the sticky sign-off drawer.
class MemoDetailScreen extends ConsumerWidget {
  const MemoDetailScreen({super.key, required this.memoId});

  final String memoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(memoDetailProvider(memoId));
    final user = ref.watch(currentUserProvider);
    final topInset = MediaQuery.viewPaddingOf(context).top + AppLayout.headerHeight;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: detail.when(
              data: (memo) => _DetailBody(memo: memo, topInset: topInset),
              loading: () => Padding(
                padding: EdgeInsets.only(top: topInset),
                child: const LoadingView(label: 'Loading memo'),
              ),
              error: (error, _) => Padding(
                padding: EdgeInsets.only(top: topInset),
                child: ErrorView(
                  failure: failureOf(error),
                  title: "Couldn't open this memo",
                  onRetry: () => ref.invalidate(memoDetailProvider(memoId)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RelayDetailHeader(
              title: 'Memo Detail',
              avatarSource: user?.avatar,
              userName: user?.displayName ?? '',
              onBack: () => context.canPop() ? context.pop() : context.go(RoutePaths.memos),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.memo, required this.topInset});

  final MemoDetail memo;
  final double topInset;

  /// Runs a decision flow and leaves the screen once the backend accepted it.
  Future<void> _decide(BuildContext context, Future<bool> Function() flow) async {
    final succeeded = await flow();
    if (succeeded && context.mounted) {
      context.canPop() ? context.pop() : context.go(RoutePaths.memos);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final busy = ref.watch(memoDecisionControllerProvider).contains(memo.id);
    final total = memo.budget?.totalCents;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ResponsiveBody(
            child: SingleChildScrollView(
              // Space for the sign-off drawer that floats over the bottom.
              padding: EdgeInsets.fromLTRB(
                20,
                topInset,
                20,
                182 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 20,
                children: <Widget>[
                  DetailPriorityRow(memo: memo, now: now),
                  DetailTitleCard(memo: memo),
                  if (memo.stages.isNotEmpty) ApprovalPathwayCard(memo: memo),
                  SummaryCard(body: memo.summary),
                  if (memo.justification case final justification?)
                    JustificationCard(justification: justification),
                  if (memo.budget case final budget?) BudgetCard(budget: budget),
                  if (memo.impact case final impact?) ImpactCard(impact: impact),
                  if (memo.signatureId case final signature?) SignatureLine(signatureId: signature),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SignOffDrawer(
            approveLabel: total == null
                ? 'Approve Memo'
                : 'Approve Memo (${Formatters.usd(total, withCents: false)})',
            isBusy: busy,
            onApprove: () => _decide(
              context,
              () => MemoDecisionFlow.approve(
                context,
                ref,
                memoId: memo.id,
                title: memo.title,
                toastInset: 190,
              ),
            ),
            onRequestRevision: () => _decide(
              context,
              () => MemoDecisionFlow.requestRevision(context, ref, memoId: memo.id),
            ),
            onDecline: () =>
                _decide(context, () => MemoDecisionFlow.decline(context, ref, memoId: memo.id)),
          ),
        ),
      ],
    );
  }
}
