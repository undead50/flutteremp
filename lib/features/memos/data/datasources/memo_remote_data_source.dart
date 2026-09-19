import 'package:dio/dio.dart';
import 'package:relay/core/network/api_endpoints.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/features/memos/data/dtos/memo_dtos.dart';
import 'package:relay/features/memos/domain/entities/approval_decision.dart';
import 'package:relay/features/memos/domain/entities/memo_detail.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

abstract interface class MemoRemoteDataSource {
  Future<MemoFeed> fetchFeed();

  Future<MemoDetail> fetchMemo(String id);

  Future<void> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  });
}

/// HTTPS implementation of the memo API contract.
final class MemoRemoteDataSourceImpl implements MemoRemoteDataSource {
  MemoRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<MemoFeed> fetchFeed() async {
    final response = await _dio.get<Object?>(ApiEndpoints.memoFeed);
    return MemoDtos.feed(JsonObject(response.data));
  }

  @override
  Future<MemoDetail> fetchMemo(String id) async {
    final response = await _dio.get<Object?>(ApiEndpoints.memo(id));
    return MemoDtos.detail(JsonObject(response.data));
  }

  @override
  Future<void> submitDecision({
    required String memoId,
    required ApprovalDecision decision,
    required String idempotencyKey,
    String? comment,
  }) async {
    await _dio.post<Object?>(
      ApiEndpoints.memoDecision(memoId),
      data: <String, Object>{'decision': decision.name, 'comment': ?comment},
      options: Options(headers: <String, String>{'Idempotency-Key': idempotencyKey}),
    );
  }
}
