import 'dart:math';

/// Generates unguessable identifiers (idempotency keys, correlation ids) from
/// the OS CSPRNG.
abstract interface class IdGenerator {
  String next();
}

final class SecureIdGenerator implements IdGenerator {
  SecureIdGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String next() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
