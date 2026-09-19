import 'package:flutter/services.dart';

/// Tactile feedback boundary (so tests and the decision flow don't touch the
/// platform channel directly).
abstract interface class Haptics {
  Future<void> success();
}

final class SystemHaptics implements Haptics {
  const SystemHaptics();

  @override
  Future<void> success() => HapticFeedback.mediumImpact();
}
