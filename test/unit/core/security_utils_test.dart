import 'package:flutter_test/flutter_test.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/security/https_url.dart';
import 'package:relay/core/security/input_sanitizer.dart';
import 'package:relay/core/security/validators.dart';

void main() {
  // Hidden characters are built from code points so this file stays plain ASCII.
  final rlo = String.fromCharCode(0x202E);
  final zeroWidth = String.fromCharCode(0x200B);
  final nul = String.fromCharCode(0);
  final bell = String.fromCharCode(7);

  group('InputSanitizer', () {
    test('removes control, zero-width and bidi-override characters', () {
      final dirty = 'Pay${rlo}00.1\$$zeroWidth now$nul$bell';
      expect(InputSanitizer.singleLine(dirty), r'Pay00.1$ now');
    });

    test('collapses whitespace and trims', () {
      expect(InputSanitizer.singleLine('  a \t\n  b   c  '), 'a b c');
    });

    test('clamps by code point without splitting surrogate pairs', () {
      const rocket = '\u{1F680}'; // one code point, two UTF-16 units
      final clamped = InputSanitizer.singleLine(rocket * 5, maxLength: 3);
      expect(clamped.runes.length, 3);
      expect(clamped, rocket * 3);
    });

    test('multiLine keeps line breaks but limits blank lines', () {
      expect(InputSanitizer.multiLine('a\r\n\r\n\r\n\r\nb'), 'a\n\nb');
      expect(InputSanitizer.multiLine('  keep\nthis  '), 'keep\nthis');
    });

    test('email is trimmed and lower-cased, but interior spaces are not "repaired"', () {
      expect(InputSanitizer.email('  Elena.Vance@Company.COM '), 'elena.vance@company.com');
      expect(InputSanitizer.email('a b@c.com'), 'a b@c.com');
    });

    test('null becomes empty', () {
      expect(InputSanitizer.singleLine(null), '');
      expect(InputSanitizer.multiLine(null), '');
      expect(InputSanitizer.email(null), '');
    });
  });

  group('Validators.email', () {
    test('accepts ordinary work emails', () {
      for (final ok in <String>[
        'a@b.co',
        'elena.vance+ops@relay-corp.example.com',
        ' Elena@Relay.io ',
      ]) {
        expect(Validators.email(ok), isNull, reason: ok);
      }
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(''), 'Enter your work email.');
      expect(Validators.email(null), 'Enter your work email.');
      for (final bad in <String>[
        'plain',
        '@no-local.com',
        'a@',
        'a@b',
        'a b@c.com',
        'a@@b.com',
        'a@b..com',
      ]) {
        expect(Validators.email(bad), 'Enter a valid email address.', reason: bad);
      }
    });

    test('rejects over-long local part and address', () {
      expect(Validators.email('${'a' * 65}@b.com'), isNotNull);
      expect(Validators.email('a@${'b' * 250}.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('requires a value but enforces no complexity policy', () {
      expect(Validators.password(''), 'Enter your password.');
      expect(Validators.password(null), 'Enter your password.');
      expect(Validators.password('x'), isNull);
    });

    test('caps length', () {
      expect(Validators.password('a' * 128), isNull);
      expect(Validators.password('a' * 129), 'Password is too long.');
    });
  });

  group('Validators.feedbackComment', () {
    test('needs 3..500 sanitised characters', () {
      expect(Validators.feedbackComment('  '), isNotNull);
      expect(Validators.feedbackComment('ab'), isNotNull);
      expect(Validators.feedbackComment('abc'), isNull);
      expect(Validators.feedbackComment('a' * 500), isNull);
      expect(Validators.feedbackComment('a' * 501), isNotNull);
    });

    test('hidden characters do not count towards the minimum', () {
      expect(Validators.feedbackComment('a$zeroWidth$zeroWidth$rlo'), isNotNull);
    });
  });

  group('SafeId', () {
    test('allows plain tokens only', () {
      for (final ok in <String>['hardware-q3', 'ENG_2024-098', 'a', 'x' * 64]) {
        expect(SafeId.isValid(ok), isTrue, reason: ok);
      }
    });

    test('blocks traversal, injection and oversize values', () {
      for (final bad in <String?>[
        null,
        '',
        '../etc/passwd',
        'a/b',
        'a b',
        'id?x=1',
        'id;drop table',
        '%2e%2e',
        'x' * 65,
      ]) {
        expect(SafeId.isValid(bad), isFalse, reason: '$bad');
      }
    });
  });

  group('parseHttpsUrl', () {
    test('accepts clean https URLs', () {
      expect(parseHttpsUrl('https://api.relay.example')?.host, 'api.relay.example');
      expect(parseHttpsUrl('https://api.relay.example/v1/'), isNotNull);
    });

    test('refuses cleartext, other schemes, credentials, queries and junk', () {
      for (final bad in <String?>[
        null,
        '',
        'http://api.relay.example',
        'javascript:alert(1)',
        'file:///etc/passwd',
        'ftp://x.example',
        'https://user:pw@api.relay.example',
        'https://api.relay.example?token=1',
        'https://api.relay.example#frag',
        'https://',
        'not a url',
      ]) {
        expect(parseHttpsUrl(bad), isNull, reason: '$bad');
      }
    });

    test('image URLs may carry a query (signed URLs) but still must be https', () {
      expect(parseHttpsImageUrl('https://cdn.example/a.png?sig=abc'), isNotNull);
      expect(parseHttpsImageUrl('http://cdn.example/a.png'), isNull);
      expect(parseHttpsImageUrl('data:image/png;base64,AAAA'), isNull);
    });
  });

  group('AppLogger.redact', () {
    test('masks emails, bearer tokens, JWTs and long secrets', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJl';
      final out = AppLogger.redact(
        'user elena@company.com sent Bearer abc.DEF-123 with $jwt and key ${'k' * 40}',
      );
      expect(out, isNot(contains('elena@company.com')));
      expect(out, isNot(contains('abc.DEF-123')));
      expect(out, isNot(contains('eyJhbGci')));
      expect(out, isNot(contains('kkkkkkkk')));
      expect(out, contains('[redacted]'));
    });

    test('leaves harmless text alone', () {
      expect(AppLogger.redact('GET /v1/memos/feed -> 200'), 'GET /v1/memos/feed -> 200');
    });
  });
}
