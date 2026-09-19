import 'package:dio/dio.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/network/api_endpoints.dart';
import 'package:relay/core/network/auth_interceptor.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/features/auth/data/dtos/auth_dtos.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';

/// Backend operations for authentication. Swap implementations (real API,
/// mock, a different vendor) by overriding one Riverpod provider.
abstract interface class AuthRemoteDataSource {
  Future<AuthGrant> login({required String email, required String password});

  Future<AuthGrant> loginWithSso();

  Future<UserProfile> fetchProfile();

  Future<void> logout();
}

/// HTTPS implementation. Error handling contract:
/// * `401`/`400` on login -> [InvalidCredentialsFailure] (deliberately vague)
/// * everything else is mapped by the repository's `guardedCall`.
final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static final Options _noAuth = Options(
    extra: <String, Object>{AuthInterceptor.skipAuthKey: true},
  );

  @override
  Future<AuthGrant> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.login,
        data: <String, String>{'email': email, 'password': password},
        options: _noAuth,
      );
      return AuthGrant.fromJson(JsonObject(response.data));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) {
        throw const AppException(InvalidCredentialsFailure());
      }
      rethrow;
    }
  }

  @override
  Future<AuthGrant> loginWithSso() {
    // The OIDC/SAML handshake needs a tenant-specific identity provider
    // (issuer, client id, redirect scheme) that is not part of this build's
    // configuration. Until one is wired in, fail with a clear, safe message
    // rather than pretending to authenticate.
    throw const AppException(NotConfiguredFailure());
  }

  @override
  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get<Object?>(ApiEndpoints.me);
    return UserProfileDto.fromJson(JsonObject(response.data)).toEntity();
  }

  @override
  Future<void> logout() async {
    await _dio.post<Object?>(ApiEndpoints.logout);
  }
}
