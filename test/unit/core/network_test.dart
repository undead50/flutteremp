import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/network/auth_interceptor.dart';
import 'package:relay/core/network/dio_error_mapper.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/core/security/token_store.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  /// Authorization header as it was *when each request was sent* (a retry
  /// mutates the same RequestOptions, so snapshots are needed).
  final List<Object?> sentAuth = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    sentAuth.add(options.headers['Authorization']);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, String body) => ResponseBody.fromString(
  body,
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

void main() {
  group('mapDioException / mapStatusCode', () {
    DioException error(DioExceptionType type, {int? status, Object? inner}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: type,
      error: inner,
      response: status == null
          ? null
          : Response<Object?>(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: status,
            ),
    );

    test('timeouts', () {
      for (final type in <DioExceptionType>[
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(mapDioException(error(type)), isA<TimeoutFailure>());
      }
    });

    test('connectivity and TLS', () {
      expect(mapDioException(error(DioExceptionType.connectionError)), isA<NetworkFailure>());
      expect(
        mapDioException(error(DioExceptionType.badCertificate)),
        isA<InsecureConnectionFailure>(),
      );
    });

    test('HTTP status codes', () {
      final expectations = <int, Type>{
        400: ValidationFailure,
        401: UnauthorizedFailure,
        403: ForbiddenFailure,
        404: NotFoundFailure,
        409: ConflictFailure,
        422: ValidationFailure,
        429: RateLimitedFailure,
        500: ServerFailure,
        503: ServerFailure,
        418: UnknownFailure,
      };
      expectations.forEach((status, type) {
        final failure = mapDioException(error(DioExceptionType.badResponse, status: status));
        expect(failure.runtimeType, type, reason: '$status');
      });
    });

    test('user-facing messages never contain technical detail', () {
      final failure = mapDioException(
        error(DioExceptionType.unknown, inner: StateError('SELECT * FROM users; secret-token-123')),
      );
      expect(failure.message, isNot(contains('secret')));
      expect(failure.message, isNot(contains('SELECT')));
    });
  });

  group('JsonObject', () {
    test('reads well-formed fields', () {
      final json = JsonObject(<String, Object?>{
        'name': '  Elena   Vance ',
        'count': 3,
        'flag': true,
        'when': '2023-10-24T09:41:00Z',
        'items': <Object?>[
          <String, Object?>{'a': 1},
        ],
      });
      expect(json.string('name'), 'Elena Vance');
      expect(json.integer('count'), 3);
      expect(json.boolean('flag'), isTrue);
      expect(json.dateTime('when').isUtc, isTrue);
      expect(json.objects('items').single.integer('a'), 1);
    });

    test('missing or wrongly typed required fields raise MalformedResponseException', () {
      final json = JsonObject(<String, Object?>{'name': 5, 'count': '3', 'when': 'yesterday'});
      expect(() => json.string('name'), throwsA(isA<MalformedResponseException>()));
      expect(() => json.string('absent'), throwsA(isA<MalformedResponseException>()));
      expect(() => json.integer('count'), throwsA(isA<MalformedResponseException>()));
      expect(() => json.dateTime('when'), throwsA(isA<MalformedResponseException>()));
      expect(() => json.object('name'), throwsA(isA<MalformedResponseException>()));
    });

    test('rejects non-object roots, out-of-range numbers and oversized lists', () {
      expect(() => JsonObject('text'), throwsA(isA<MalformedResponseException>()));
      expect(() => JsonObject(<Object?>[1]), throwsA(isA<MalformedResponseException>()));
      expect(
        () => JsonObject(<String, Object?>{'n': -1}).integer('n'),
        throwsA(isA<MalformedResponseException>()),
      );
      expect(
        () => JsonObject(<String, Object?>{'n': 1.5}).integer('n'),
        throwsA(isA<MalformedResponseException>()),
      );
      expect(
        () =>
            JsonObject(<String, Object?>{'l': List<Object?>.filled(5, <String, Object?>{})})
                .objects('l', maxItems: 4),
        throwsA(isA<MalformedResponseException>()),
      );
    });

    test('sanitises and length-limits text', () {
      final zeroWidth = String.fromCharCode(0x200B);
      final json = JsonObject(<String, Object?>{'t': 'ab${zeroWidth}cdefghij'});
      expect(json.string('t', maxLength: 5), 'abcde');
    });

    test('unknown enum values throw unless a fallback is given', () {
      final json = JsonObject(<String, Object?>{'k': 'mystery'});
      expect(() => json.enumValue('k', Axis.values), throwsA(isA<MalformedResponseException>()));
      expect(json.enumValue('k', Axis.values, fallback: Axis.vertical), Axis.vertical);
    });

    test('exception text carries the field name, never the value', () {
      try {
        JsonObject(<String, Object?>{'secret': 42}).string('secret');
        fail('should throw');
      } on MalformedResponseException catch (e) {
        expect(e.toString(), contains('secret'));
        expect(e.toString(), isNot(contains('42')));
      }
    });
  });

  group('AuthInterceptor', () {
    late InMemoryTokenStore tokens;
    late _Adapter adapter;
    late Dio dio;
    late int refreshCalls;
    late int expiredCalls;
    var refreshResult = true;

    setUp(() async {
      tokens = InMemoryTokenStore();
      await tokens.write(const AuthTokens(accessToken: 'old', refreshToken: 'refresh-1'));
      refreshCalls = 0;
      expiredCalls = 0;
      refreshResult = true;

      adapter = _Adapter((options) async {
        final auth = options.headers['Authorization'];
        if (options.path == '/data') {
          return auth == 'Bearer new' ? _json(200, '{"ok":true}') : _json(401, '{}');
        }
        return _json(200, '{}');
      });
      dio = Dio(BaseOptions(baseUrl: 'https://api.test.example'))..httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokens: tokens,
          refresher: () async {
            refreshCalls++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            if (refreshResult) {
              await tokens.write(const AuthTokens(accessToken: 'new', refreshToken: 'refresh-2'));
            }
            return refreshResult;
          },
          onSessionExpired: () => expiredCalls++,
        ),
      );
    });

    test('attaches the bearer token', () async {
      await dio.get<Object?>('/other');
      expect(adapter.requests.single.headers['Authorization'], 'Bearer old');
    });

    test('a 401 triggers one refresh and one retry with the new token', () async {
      final response = await dio.get<Object?>('/data');
      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(adapter.sentAuth, <Object?>['Bearer old', 'Bearer new']);
      expect(expiredCalls, 0);
    });

    test('concurrent 401s share a single refresh (single-flight)', () async {
      final results = await Future.wait(<Future<Response<Object?>>>[
        dio.get<Object?>('/data'),
        dio.get<Object?>('/data'),
        dio.get<Object?>('/data'),
      ]);
      expect(results.every((r) => r.statusCode == 200), isTrue);
      expect(refreshCalls, 1);
    });

    test('a failed refresh reports session expiry and surfaces the 401', () async {
      refreshResult = false;
      await expectLater(
        dio.get<Object?>('/data'),
        throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
      );
      expect(refreshCalls, 1);
      expect(expiredCalls, 1);
    });

    test('a request is retried at most once', () async {
      // The retry also 401s (server keeps rejecting): no refresh loop.
      adapter = _Adapter((_) async => _json(401, '{}'));
      dio.httpClientAdapter = adapter;
      await expectLater(dio.get<Object?>('/data'), throwsA(isA<DioException>()));
      expect(refreshCalls, 1);
      expect(adapter.requests, hasLength(2));
    });

    test('skipAuth requests get no token and never trigger a refresh', () async {
      adapter = _Adapter((_) async => _json(401, '{}'));
      dio.httpClientAdapter = adapter;
      await expectLater(
        dio.post<Object?>(
          '/login',
          options: Options(extra: <String, Object>{AuthInterceptor.skipAuthKey: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
      expect(refreshCalls, 0);
      expect(expiredCalls, 0);
    });
  });
}

/// Keeps the enum used above local to this file.
enum Axis { horizontal, vertical }
