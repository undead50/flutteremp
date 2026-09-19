import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:relay/core/logging/app_logger.dart';

/// OAuth-style token pair. `toString` is redacted so a token can never end up
/// in a log line or a crash report by accident.
final class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  @override
  String toString() => 'AuthTokens(<redacted>)';
}

/// Persistence boundary for credentials. Only ever backed by platform secure
/// storage in production (Keychain / Android Keystore).
abstract interface class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}

final class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage, required AppLogger logger})
    : _storage = storage ?? _defaultStorage,
      _logger = logger;

  static const String _accessKey = 'relay.auth.access_token';
  static const String _refreshKey = 'relay.auth.refresh_token';

  // `first_unlock_this_device`: readable after the first unlock (needed for
  // background refresh) but never migrated to another device or iCloud backup.
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  final FlutterSecureStorage _storage;
  final AppLogger _logger;

  @override
  Future<AuthTokens?> read() async {
    try {
      final access = await _storage.read(key: _accessKey);
      final refresh = await _storage.read(key: _refreshKey);
      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        return null;
      }
      return AuthTokens(accessToken: access, refreshToken: refresh);
    } on PlatformException catch (e) {
      // A corrupted keystore entry (e.g. after a restore) must not brick the
      // app: drop it and make the user sign in again.
      _logger.warning('Secure storage read failed', error: e);
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } on PlatformException catch (e) {
      _logger.warning('Secure storage clear failed', error: e);
    }
  }
}

/// Test double. Never wired up in a real build.
final class InMemoryTokenStore implements TokenStore {
  AuthTokens? _tokens;

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
