import 'dart:async';

import 'package:dio/dio.dart';
import 'package:relay/core/security/token_store.dart';

/// Attempts to obtain a fresh access token; returns whether it succeeded.
typedef TokenRefresher = Future<bool> Function();

/// Attaches the bearer token and transparently recovers from one expired
/// access token per request.
///
/// * Requests flagged with [skipAuthKey] (login, refresh) never get a token.
/// * Concurrent 401s share a single refresh call (single-flight).
/// * A request is retried at most once; if the refresh fails the session is
///   reported as expired and the original 401 is surfaced.
///
/// This only manages *credentials*. Whether the user may perform an action is
/// decided by the backend; a 403 is surfaced as-is and never bypassed.
final class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStore tokens,
    required TokenRefresher refresher,
    required void Function() onSessionExpired,
  }) : _dio = dio,
       _tokens = tokens,
       _refresher = refresher,
       _onSessionExpired = onSessionExpired;

  static const String skipAuthKey = 'relay.skipAuth';
  static const String _retriedKey = 'relay.authRetried';

  final Dio _dio;
  final TokenStore _tokens;
  final TokenRefresher _refresher;
  final void Function() _onSessionExpired;

  Future<bool>? _refreshInFlight;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuthKey] != true) {
      final tokens = await _tokens.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final canRecover =
        err.response?.statusCode == 401 &&
        request.extra[skipAuthKey] != true &&
        request.extra[_retriedKey] != true;

    if (!canRecover) return handler.next(err);

    final refreshed = await (_refreshInFlight ??= _refresher().whenComplete(
      () => _refreshInFlight = null,
    ));

    if (!refreshed) {
      _onSessionExpired();
      return handler.next(err);
    }

    try {
      final tokens = await _tokens.read();
      request.extra[_retriedKey] = true;
      if (tokens != null) {
        request.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
      handler.resolve(await _dio.fetch<Object?>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
