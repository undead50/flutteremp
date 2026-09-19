import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/security/input_sanitizer.dart';
import 'package:relay/core/security/validators.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';
import 'package:relay/features/memos/domain/repositories/memo_repository.dart';

final class GetMemoFeed {
  const GetMemoFeed(this._repository);

  final MemoRepository _repository;

  Future<Result<MemoFeed>> call() => _repository.getFeed();
}

final class GetMemoDetail {
  const GetMemoDetail(this._repository);

  final MemoRepository _repository;

  Future<Result<MemoDetail>> call(String id) {
    // Ids arrive from deep links; refuse anything that isn't a plain token
    // before it gets anywhere near a request path.
    if (!SafeId.isValid(id)) {
      return Future<Result<MemoDetail>>.value(const Result<MemoDetail>.failure(NotFoundFailure()));
    }
    return _repository.getMemo(id);
  }
}

/// Approve / request revision / decline a memo.
///
/// Business rules enforced here (and again by the backend):
/// * the memo id must be a safe token;
/// * `requestRevision` and `decline` need a written note of 3-500 characters,
///   which is sanitised before it is sent;
/// * `approve` never carries a note.
final class SubmitMemoDecision {
  const SubmitMemoDecision(this._repository);

  final MemoRepository _repository;

  Future<Result<void>> call({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) {
    if (!SafeId.isValid(memoId)) {
      return Future<Result<void>>.value(const Result<void>.failure(NotFoundFailure()));
    }

    String? note;
    if (decision.requiresComment) {
      if (Validators.feedbackComment(comment) != null) {
        return Future<Result<void>>.value(
          const Result<void>.failure(
            ValidationFailure('Add a short note explaining your decision.'),
          ),
        );
      }
      note = InputSanitizer.multiLine(comment, maxLength: Validators.maxCommentLength);
    }

    return _repository.submitDecision(
      memoId: memoId,
      decision: decision,
      idempotencyKey: idempotencyKey,
      comment: note,
    );
  }
}
