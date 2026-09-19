import 'package:relay/core/security/https_url.dart';

enum AppEnvironment {
  dev,
  staging,
  prod;

  static AppEnvironment? tryParse(String value) {
    for (final env in values) {
      if (env.name == value) return env;
    }
    return null;
  }
}

/// Raised when the build was started with missing or unsafe configuration.
/// The app fails *closed*: it shows a configuration error instead of running
/// with insecure defaults (OWASP A02).
final class ConfigurationException implements Exception {
  const ConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ConfigurationException: $message';
}

/// Build-time configuration, injected with `--dart-define-from-file`.
///
/// Values here are compiled into the binary and are therefore **not secret**.
/// API keys, passwords and tokens must never be supplied this way.
final class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.useMockBackend,
    required this.enableLogging,
    this.privacyUrl,
    this.helpdeskUrl,
    this.trustCenterUrl,
  });

  /// Config for tests and previews: mock backend, no network.
  const AppConfig.mock()
    : environment = AppEnvironment.dev,
      apiBaseUrl = null,
      useMockBackend = true,
      enableLogging = false,
      privacyUrl = null,
      helpdeskUrl = null,
      trustCenterUrl = null;

  factory AppConfig.fromEnvironment() => AppConfig.parse(
    environment: const String.fromEnvironment('APP_ENV'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    useMockBackend: const String.fromEnvironment('USE_MOCK_BACKEND'),
    enableLogging: const String.fromEnvironment('ENABLE_LOGGING'),
    privacyUrl: const String.fromEnvironment('PRIVACY_URL'),
    helpdeskUrl: const String.fromEnvironment('HELPDESK_URL'),
    trustCenterUrl: const String.fromEnvironment('TRUST_CENTER_URL'),
  );

  /// Validates raw values and returns a config, or throws [ConfigurationException].
  factory AppConfig.parse({
    required String environment,
    String apiBaseUrl = '',
    String useMockBackend = '',
    String enableLogging = '',
    String privacyUrl = '',
    String helpdeskUrl = '',
    String trustCenterUrl = '',
  }) {
    final env = AppEnvironment.tryParse(environment);
    if (env == null) {
      throw const ConfigurationException(
        'APP_ENV must be one of: dev, staging, prod. '
        'Run with --dart-define-from-file=config/dev.json',
      );
    }

    final mock = useMockBackend == 'true';
    if (mock && env != AppEnvironment.dev) {
      throw const ConfigurationException(
        'USE_MOCK_BACKEND is only allowed in the dev environment.',
      );
    }

    Uri? baseUrl;
    if (!mock) {
      baseUrl = parseHttpsUrl(apiBaseUrl);
      if (baseUrl == null) {
        throw const ConfigurationException(
          'API_BASE_URL must be an https:// URL without credentials, query or fragment.',
        );
      }
    }

    Uri? optionalUrl(String raw, String key) {
      if (raw.isEmpty) return null;
      final parsed = parseHttpsUrl(raw);
      if (parsed == null) {
        throw ConfigurationException('$key must be an https:// URL.');
      }
      return parsed;
    }

    return AppConfig._(
      environment: env,
      apiBaseUrl: baseUrl,
      useMockBackend: mock,
      // Verbose logging is never permitted in production builds.
      enableLogging: enableLogging == 'true' && env != AppEnvironment.prod,
      privacyUrl: optionalUrl(privacyUrl, 'PRIVACY_URL'),
      helpdeskUrl: optionalUrl(helpdeskUrl, 'HELPDESK_URL'),
      trustCenterUrl: optionalUrl(trustCenterUrl, 'TRUST_CENTER_URL'),
    );
  }

  final AppEnvironment environment;

  /// `null` only when [useMockBackend] is true.
  final Uri? apiBaseUrl;
  final bool useMockBackend;
  final bool enableLogging;
  final Uri? privacyUrl;
  final Uri? helpdeskUrl;
  final Uri? trustCenterUrl;
}
