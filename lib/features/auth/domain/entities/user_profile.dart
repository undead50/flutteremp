import 'package:flutter/foundation.dart';

/// The signed-in employee. Contains no credentials; tokens never leave the
/// data layer.
@immutable
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.title,
    required this.department,
    required this.level,
    required this.employeeCode,
    required this.signedMemoCount,
    this.avatar,
  });

  final String id;
  final String displayName;

  /// e.g. `VP Operations`.
  final String title;

  /// e.g. `Relay Core`.
  final String department;

  /// e.g. `Staff Level 9`.
  final String level;

  /// e.g. `#8942-EV`.
  final String employeeCode;
  final int signedMemoCount;

  /// `asset:<path>` (mock data) or an https URL.
  final String? avatar;

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? displayName : parts.first;
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.id == id &&
      other.displayName == displayName &&
      other.title == title &&
      other.department == department &&
      other.level == level &&
      other.employeeCode == employeeCode &&
      other.signedMemoCount == signedMemoCount &&
      other.avatar == avatar;

  @override
  int get hashCode =>
      Object.hash(id, displayName, title, department, level, employeeCode, signedMemoCount, avatar);
}
