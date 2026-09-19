import 'package:flutter/foundation.dart';

/// Colleague temporarily allowed to sign on the user's behalf.
@immutable
final class SignOffProxy {
  const SignOffProxy({required this.name, required this.statusLabel, this.avatar});

  final String name;

  /// e.g. `Proxy standby · 48h limit`.
  final String statusLabel;
  final String? avatar;
}
