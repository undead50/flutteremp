import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/platform/haptics.dart';
import 'package:relay/core/security/biometric_authenticator.dart';
import 'package:relay/core/security/external_link_launcher.dart';
import 'package:relay/core/security/id_generator.dart';
import 'package:relay/features/memos/data/datasources/memo_remote_data_source.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

final class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({
    this.available = true,
    this.outcome = const Result<void>.success(null),
  });

  bool available;
  Result<void> outcome;
  final List<String> reasons = <String>[];

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<void>> authenticate({required String reason}) async {
    reasons.add(reason);
    return outcome;
  }
}

final class RecordingHaptics implements Haptics {
  int successCount = 0;

  @override
  Future<void> success() async => successCount++;
}

final class SequentialIdGenerator implements IdGenerator {
  int _next = 0;

  @override
  String next() => 'key-${_next++}';
}

final class RecordingLinkLauncher implements ExternalLinkLauncher {
  RecordingLinkLauncher({this.succeeds = true});

  final bool succeeds;
  final List<Uri?> opened = <Uri?>[];

  @override
  Future<bool> open(Uri? url) async {
    opened.add(url);
    return succeeds;
  }
}

/// Wraps another data source and lets a test make individual calls fail.
final class ProgrammableMemoDataSource implements MemoRemoteDataSource {
  ProgrammableMemoDataSource(this.inner);

  final MemoRemoteDataSource inner;
  Failure? feedFailure;
  Failure? detailFailure;
  Failure? decisionFailure;
  int feedCalls = 0;
  final List<({String memoId, ApprovalDecision decision, String key, String? comment})> decisions =
      <({String memoId, ApprovalDecision decision, String key, String? comment})>[];

  @override
  Future<MemoFeed> fetchFeed() async {
    feedCalls++;
    if (feedFailure case final failure?) throw AppException(failure);
    return inner.fetchFeed();
  }

  @override
  Future<MemoDetail> fetchMemo(String id) async {
    if (detailFailure case final failure?) throw AppException(failure);
    return inner.fetchMemo(id);
  }

  @override
  Future<void> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) async {
    decisions.add((memoId: memoId, decision: decision, key: idempotencyKey, comment: comment));
    if (decisionFailure case final failure?) throw AppException(failure);
    return inner.submitDecision(
      memoId: memoId,
      decision: decision,
      idempotencyKey: idempotencyKey,
      comment: comment,
    );
  }
}
