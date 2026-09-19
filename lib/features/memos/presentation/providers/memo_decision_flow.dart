import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/widgets/relay_dialogs.dart';
import 'package:relay/core/widgets/relay_snackbar.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/presentation/providers/memo_providers.dart';

/// UI choreography for a sign-off: ask -> (biometric) -> submit -> report.
/// Shared by the feed's *Quick Approve* and the detail screen's buttons so both
/// behave identically. Returns `true` when the backend accepted the decision.
abstract final class MemoDecisionFlow {
  static Future<bool> approve(
    BuildContext context,
    WidgetRef ref, {
    required String memoId,
    required String title,
    double toastInset = 24,
  }) async {
    final confirmed = await showRelayConfirmDialog(
      context,
      title: 'Approve this memo?',
      message: 'You are signing off on "$title". Your approval is recorded in the audit trail.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !context.mounted) return false;

    final result = await ref
        .read(memoDecisionControllerProvider.notifier)
        .decide(memoId: memoId, decision: ApprovalDecision.approve);
    if (!context.mounted) return result.isSuccess;
    return _report(context, result, success: 'Memo approved', toastInset: toastInset);
  }

  static Future<bool> requestRevision(
    BuildContext context,
    WidgetRef ref, {
    required String memoId,
  }) async {
    final note = await showRelayFeedbackDialog(
      context,
      title: 'Request a revision',
      message: 'Tell the author what needs to change before you can sign off.',
      hint: 'What should be revised?',
      confirmLabel: 'Send request',
    );
    if (note == null || !context.mounted) return false;

    final result = await ref
        .read(memoDecisionControllerProvider.notifier)
        .decide(memoId: memoId, decision: ApprovalDecision.requestRevision, comment: note);
    if (!context.mounted) return result.isSuccess;
    return _report(context, result, success: 'Revision requested');
  }

  static Future<bool> decline(BuildContext context, WidgetRef ref, {required String memoId}) async {
    final note = await showRelayFeedbackDialog(
      context,
      title: 'Decline this memo?',
      message: 'The author will see your note. This cannot be undone.',
      hint: 'Why are you declining?',
      confirmLabel: 'Decline',
      destructive: true,
    );
    if (note == null || !context.mounted) return false;

    final result = await ref
        .read(memoDecisionControllerProvider.notifier)
        .decide(memoId: memoId, decision: ApprovalDecision.decline, comment: note);
    if (!context.mounted) return result.isSuccess;
    return _report(context, result, success: 'Memo declined');
  }

  static bool _report(
    BuildContext context,
    Result<void> result, {
    required String success,
    double toastInset = 24,
  }) {
    switch (result) {
      case Success<void>():
        RelaySnackbar.show(context, success, kind: SnackKind.success, bottomInset: toastInset);
        return true;
      case Err<void>(:final failure):
        RelaySnackbar.show(
          context,
          failure.message,
          kind: SnackKind.error,
          bottomInset: toastInset,
        );
        return false;
    }
  }
}
