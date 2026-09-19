import 'package:dio/dio.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/dio_error_mapper.dart';

/// Runs a data-source call and folds every possible error into a [Result].
///
/// Repositories wrap *all* data access in this so that no exception can escape
/// into the domain/presentation layers and no raw error text can reach the UI.
Future<Result<T>> guardedCall<T>(Future<T> Function() action, AppLogger logger) async {
  try {
    return Result<T>.success(await action());
  } on AppException catch (e) {
    return Result<T>.failure(e.failure);
  } on DioException catch (e) {
    return Result<T>.failure(mapDioException(e));
  } on MalformedResponseException catch (e) {
    logger.warning('Malformed response', error: e);
    return const Result<Never>.failure(MalformedResponseFailure());
  } on FormatException catch (e) {
    logger.warning('Unparseable response', error: e);
    return const Result<Never>.failure(MalformedResponseFailure());
  } on Object catch (e, st) {
    logger.error('Unexpected error in data layer', error: e, stackTrace: st);
    return const Result<Never>.failure(UnknownFailure());
  }
}
