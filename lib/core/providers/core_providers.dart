import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/config/app_config.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/network/api_client.dart';
import 'package:relay/core/security/biometric_authenticator.dart';
import 'package:relay/core/security/external_link_launcher.dart';
import 'package:relay/core/security/id_generator.dart';
import 'package:relay/core/security/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Composition root of the app. Everything environment-specific is injected
/// through these providers, so tests and previews override them instead of
/// touching globals.

/// Must be overridden in `bootstrap` (or tests) with the validated config.
final Provider<AppConfig> appConfigProvider = Provider<AppConfig>(
  (ref) => throw StateError('appConfigProvider must be overridden'),
);

/// Must be overridden with an initialised instance before `runApp`.
final Provider<SharedPreferences> sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('sharedPreferencesProvider must be overridden'),
);

final Provider<AppLogger> loggerProvider = Provider<AppLogger>(
  (ref) => AppLogger(verbose: ref.watch(appConfigProvider).enableLogging),
);

final Provider<DateTime Function()> clockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final Provider<IdGenerator> idGeneratorProvider = Provider<IdGenerator>(
  (ref) => SecureIdGenerator(),
);

final Provider<TokenStore> tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureTokenStore(logger: ref.watch(loggerProvider)),
);

final Provider<BiometricAuthenticator> biometricAuthenticatorProvider =
    Provider<BiometricAuthenticator>((ref) => LocalAuthBiometricAuthenticator());

final Provider<ExternalLinkLauncher> externalLinkLauncherProvider = Provider<ExternalLinkLauncher>(
  (ref) => const UrlLauncherExternalLinks(),
);

/// Lets the network layer tell the session controller that credentials died,
/// without the network layer depending on any feature.
final class SessionEvents {
  final StreamController<void> _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}

final Provider<SessionEvents> sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

/// Authenticated HTTPS client. Created lazily, so mock-backend builds (which
/// have no API base URL) never construct it.
final Provider<Dio> dioProvider = Provider<Dio>((ref) {
  final dio = createApiClient(
    config: ref.watch(appConfigProvider),
    tokens: ref.watch(tokenStoreProvider),
    onSessionExpired: ref.watch(sessionEventsProvider).notifyExpired,
    logger: ref.watch(loggerProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});
