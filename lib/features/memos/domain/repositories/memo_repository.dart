import 'package:relay/core/error/result.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

abstract interface class MemoRepository {
  Future<Result<MemoFeed>> getFeed();

  Future<Result<MemoDetail>> getMemo(String id);

  /// [idempotencyKey] lets the backend ignore a retried request whose first
  /// attempt actually succeeded, so a flaky network can't double-approve.
  /// The backend, not this client, decides whether the caller may decide.
  Future<Result<void>> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  });
}
