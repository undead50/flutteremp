import 'package:dio/dio.dart';
import 'package:relay/core/config/app_config.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/auth_interceptor.dart';
import 'package:relay/core/network/api_endpoints.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/core/security/token_store.dart';

/// Shared transport options. HTTPS is guaranteed by [AppConfig]; redirects are
/// not followed so a hostile or misconfigured hop can't downgrade to HTTP.
BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl!.toString(),
  connectTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  responseType: ResponseType.json,
  followRedirects: false,
  headers: <String, Object>{'Accept': 'application/json'},
);

/// Builds the authenticated API client.
Dio createApiClient({
  required AppConfig config,
  required TokenStore tokens,
  required void Function() onSessionExpired,
  required AppLogger logger,
}) {
  final dio = Dio(_baseOptions(config));
  final refresher = HttpTokenRefresher(config: config, tokens: tokens, logger: logger);

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokens: tokens,
      refresher: refresher.call,
      onSessionExpired: onSessionExpired,
    ),
  );
  if (config.enableLogging) dio.interceptors.add(_SafeLogInterceptor(logger));
  return dio;
}

/// Logs `METHOD /path -> status` only. Headers, query strings and bodies are
/// never logged because they carry tokens and personal data.
final class _SafeLogInterceptor extends Interceptor {
  _SafeLogInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final r = response.requestOptions;
    _logger.debug('${r.method} ${r.uri.path} -> ${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final r = err.requestOptions;
    _logger.debug('${r.method} ${r.uri.path} -> ${err.response?.statusCode ?? err.type.name}');
    handler.next(err);
  }
}

/// Exchanges the stored refresh token for a new pair using a bare client (no
/// interceptors, so it can never recurse into itself).
final class HttpTokenRefresher {
  HttpTokenRefresher({
    required AppConfig config,
    required TokenStore tokens,
    required AppLogger logger,
    Dio? dio,
  }) : _dio = dio ?? Dio(_baseOptions(config)),
       _tokens = tokens,
       _logger = logger;

  final Dio _dio;
  final TokenStore _tokens;
  final AppLogger _logger;

  Future<bool> call() async {
    final current = await _tokens.read();
    if (current == null) return false;
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.refresh,
        data: <String, String>{'refreshToken': current.refreshToken},
      );
      final json = JsonObject(response.data);
      await _tokens.write(
        AuthTokens(
          accessToken: json.string('accessToken', maxLength: 8192),
          refreshToken: json.string('refreshToken', maxLength: 8192),
        ),
      );
      return true;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // The server said the refresh token is no good: forget it. Transient
      // network errors keep the tokens so the next attempt can succeed.
      if (status == 400 || status == 401 || status == 403) await _tokens.clear();
      _logger.debug('Token refresh failed');
      return false;
    } on Object catch (e) {
      _logger.warning('Token refresh returned an invalid payload', error: e);
      return false;
    }
  }
}
