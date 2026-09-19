import 'package:relay/core/error/result.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/guarded_call.dart';
import 'package:relay/features/memos/data/datasources/memo_remote_data_source.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';
import 'package:relay/features/memos/domain/repositories/memo_repository.dart';

final class MemoRepositoryImpl implements MemoRepository {
  MemoRepositoryImpl({required MemoRemoteDataSource remote, required AppLogger logger})
    : _remote = remote,
      _logger = logger;

  final MemoRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<MemoFeed>> getFeed() => guardedCall(_remote.fetchFeed, _logger);

  @override
  Future<Result<MemoDetail>> getMemo(String id) =>
      guardedCall(() => _remote.fetchMemo(id), _logger);

  @override
  Future<Result<void>> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) {
    return guardedCall<void>(
      () => _remote.submitDecision(
        memoId: memoId,
        decision: decision,
        idempotencyKey: idempotencyKey,
        comment: comment,
      ),
      _logger,
    );
  }
}
