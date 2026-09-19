import 'dart:io';

import 'package:dio/dio.dart';
import 'package:relay/core/error/failure.dart';

/// Converts transport errors into user-safe [Failure]s.
///
/// Response bodies and exception messages are intentionally ignored: they can
/// contain stack traces, SQL, internal hostnames or tokens (OWASP A10).
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badCertificate:
      return const InsecureConnectionFailure();
    case DioExceptionType.badResponse:
      return mapStatusCode(e.response?.statusCode);
    case DioExceptionType.cancel:
      return const UnknownFailure();
    case DioExceptionType.unknown:
      final inner = e.error;
      if (inner is SocketException) return const NetworkFailure();
      if (inner is HandshakeException || inner is TlsException) {
        return const InsecureConnectionFailure();
      }
      return const UnknownFailure();
  }
}

Failure mapStatusCode(int? status) {
  if (status == null) return const UnknownFailure();
  return switch (status) {
    400 || 422 => const ValidationFailure(),
    401 => const UnauthorizedFailure(),
    403 => const ForbiddenFailure(),
    404 => const NotFoundFailure(),
    409 => const ConflictFailure(),
    429 => const RateLimitedFailure(),
    >= 500 && < 600 => const ServerFailure(),
    _ => const UnknownFailure(),
  };
}
