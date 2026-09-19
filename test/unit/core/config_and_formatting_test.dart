import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/config/app_config.dart';
import 'package:relay/core/utils/formatters.dart';

void main() {
  group('AppConfig.parse', () {
    test('accepts a complete staging config', () {
      final config = AppConfig.parse(
        environment: 'staging',
        apiBaseUrl: 'https://api.staging.relay.example',
        enableLogging: 'true',
        privacyUrl: 'https://relay.example/privacy',
      );
      expect(config.environment, AppEnvironment.staging);
      expect(config.useMockBackend, isFalse);
      expect(config.apiBaseUrl?.host, 'api.staging.relay.example');
      expect(config.enableLogging, isTrue);
      expect(config.privacyUrl?.path, '/privacy');
    });

    test('dev may use the mock backend without a base URL', () {
      final config = AppConfig.parse(environment: 'dev', useMockBackend: 'true');
      expect(config.useMockBackend, isTrue);
      expect(config.apiBaseUrl, isNull);
    });

    test('fails closed on a missing or unknown environment', () {
      expect(() => AppConfig.parse(environment: ''), throwsA(isA<ConfigurationException>()));
      expect(() => AppConfig.parse(environment: 'qa'), throwsA(isA<ConfigurationException>()));
    });

    test('production can never run against the mock backend', () {
      expect(
        () => AppConfig.parse(environment: 'prod', useMockBackend: 'true'),
        throwsA(isA<ConfigurationException>()),
      );
      expect(
        () => AppConfig.parse(environment: 'staging', useMockBackend: 'true'),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('refuses cleartext or malformed API URLs', () {
      for (final url in <String>[
        '',
        'http://api.relay.example',
        'https://user:pass@api.relay.example',
        'https://api.relay.example?x=1',
        'ws://api.relay.example',
      ]) {
        expect(
          () => AppConfig.parse(environment: 'prod', apiBaseUrl: url),
          throwsA(isA<ConfigurationException>()),
          reason: url,
        );
      }
    });

    test('verbose logging is forced off in production', () {
      final config = AppConfig.parse(
        environment: 'prod',
        apiBaseUrl: 'https://api.relay.example',
        enableLogging: 'true',
      );
      expect(config.enableLogging, isFalse);
    });

    test('an invalid optional link is a configuration error, not silently ignored', () {
      expect(
        () => AppConfig.parse(
          environment: 'prod',
          apiBaseUrl: 'https://api.relay.example',
          helpdeskUrl: 'http://insecure.example',
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });

  group('Formatters', () {
    test('usd formats integer cents with grouping', () {
      expect(Formatters.usd(485000), r'$4,850.00');
      expect(Formatters.usd(485000, withCents: false), r'$4,850');
      expect(Formatters.usd(5), r'$0.05');
      expect(Formatters.usd(-124000, withCents: false), r'-$1,240');
      expect(Formatters.usd(123456789), r'$1,234,567.89');
    });

    test('expiresIn rounds up so 1h59m reads as 2h', () {
      final now = DateTime(2023, 10, 24, 9);
      expect(
        Formatters.expiresIn(now.add(const Duration(hours: 1, minutes: 59)), now),
        'Expiring in 2h',
      );
      expect(Formatters.expiresIn(now.add(const Duration(minutes: 40)), now), 'Expiring in 40m');
      expect(Formatters.expiresIn(now.add(const Duration(seconds: 20)), now), 'Expiring in 1m');
      expect(Formatters.expiresIn(now.subtract(const Duration(minutes: 1)), now), 'Expired');
    });

    test('relativeAgo picks the largest whole unit', () {
      final now = DateTime(2023, 10, 24, 12);
      expect(Formatters.relativeAgo(now.subtract(const Duration(seconds: 10)), now), 'just now');
      expect(Formatters.relativeAgo(now.subtract(const Duration(minutes: 45)), now), '45m ago');
      expect(
        Formatters.relativeAgo(now.subtract(const Duration(hours: 4, minutes: 59)), now),
        '4h ago',
      );
      expect(Formatters.relativeAgo(now.subtract(const Duration(days: 3)), now), '3d ago');
    });

    test('dates and times match the design copy', () {
      expect(Formatters.shortDate(DateTime(2023, 10, 24)), 'Tue, Oct 24');
      expect(Formatters.clockTime(DateTime(2023, 10, 24, 14)), '2:00 PM');
      expect(Formatters.clockTime(DateTime(2023, 10, 24, 0, 5)), '12:05 AM');
      expect(Formatters.timelineTime(DateTime(2023, 10, 24, 9, 14)), '09:14 AM');
    });

    test('initials and file sizes', () {
      expect(Formatters.initials('Marcus Vance'), 'MV');
      expect(Formatters.initials('  cher '), 'C');
      expect(Formatters.initials(''), '?');
      expect(Formatters.fileSize(2516582), '2.4 MB');
      expect(Formatters.fileSize(900), '900 B');
    });
  });
}
