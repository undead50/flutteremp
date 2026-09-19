import 'package:dio/dio.dart';
import 'package:relay/core/network/api_endpoints.dart';
import 'package:relay/core/network/json_reader.dart';
import 'package:relay/core/security/https_url.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';

abstract interface class SettingsRemoteDataSource {
  Future<SignOffProxy?> fetchSignOffProxy();
}

final class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<SignOffProxy?> fetchSignOffProxy() async {
    final response = await _dio.get<Object?>(ApiEndpoints.signOffProxy);
    // 204 / empty body means "no proxy configured".
    if (response.statusCode == 204 || response.data == null) return null;
    final json = JsonObject(response.data);
    return SignOffProxy(
      name: json.string('name', maxLength: 80),
      statusLabel: json.optString('statusLabel', maxLength: 80) ?? '',
      avatar: parseHttpsImageUrl(json.optString('avatarUrl', maxLength: 2048))?.toString(),
    );
  }
}

/// Offline stand-in used by mock builds and tests.
final class SettingsMockDataSource implements SettingsRemoteDataSource {
  SettingsMockDataSource({this.latency = const Duration(milliseconds: 400)});

  final Duration latency;

  @override
  Future<SignOffProxy?> fetchSignOffProxy() async {
    await Future<void>.delayed(latency);
    // No photo asset exists for this person in the design export, so the
    // avatar falls back to initials.
    return const SignOffProxy(name: 'Marcus Brody', statusLabel: 'Proxy standby · 48h limit');
  }
}
