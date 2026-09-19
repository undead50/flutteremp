import 'package:flutter/foundation.dart';

/// "Text Size & Readability" presets. The value multiplies the system text
/// scale, so a user who already enlarged text in OS settings keeps that too.
enum TextSizePreset {
  standard(1),
  large(1.15),
  extraLarge(1.3);

  const TextSizePreset(this.scale);

  final double scale;
}

/// Colour theme. `system` follows the device's light/dark setting.
enum AppearanceMode { system, light, dark }

/// Feeds that can be switched on or off on the primary deck.
enum WorkspaceModule { executiveMemos, expenseApprovals, teamLeave, policyRevisions }

@immutable
final class UserPreferences {
  const UserPreferences({
    this.appearance = AppearanceMode.system,
    this.textSize = TextSizePreset.standard,
    this.hapticOnApproval = true,
    this.highContrast = false,
    this.biometricRecheck = true,
    this.activeModules = const <WorkspaceModule>{...WorkspaceModule.values},
  });

  static const UserPreferences defaults = UserPreferences();

  final AppearanceMode appearance;
  final TextSizePreset textSize;

  /// Subtle pulse when a sign-off succeeds.
  final bool hapticOnApproval;

  /// Visible borders on cards and inputs.
  final bool highContrast;

  /// Ask for Face ID / fingerprint before a sign-off. Local friction only; the
  /// backend must enforce any step-up requirement itself.
  final bool biometricRecheck;
  final Set<WorkspaceModule> activeModules;

  UserPreferences copyWith({
    AppearanceMode? appearance,
    TextSizePreset? textSize,
    bool? hapticOnApproval,
    bool? highContrast,
    bool? biometricRecheck,
    Set<WorkspaceModule>? activeModules,
  }) {
    return UserPreferences(
      appearance: appearance ?? this.appearance,
      textSize: textSize ?? this.textSize,
      hapticOnApproval: hapticOnApproval ?? this.hapticOnApproval,
      highContrast: highContrast ?? this.highContrast,
      biometricRecheck: biometricRecheck ?? this.biometricRecheck,
      activeModules: activeModules ?? this.activeModules,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserPreferences &&
      other.appearance == appearance &&
      other.textSize == textSize &&
      other.hapticOnApproval == hapticOnApproval &&
      other.highContrast == highContrast &&
      other.biometricRecheck == biometricRecheck &&
      setEquals(other.activeModules, activeModules);

  @override
  int get hashCode => Object.hash(
    appearance,
    textSize,
    hapticOnApproval,
    highContrast,
    biometricRecheck,
    Object.hashAllUnordered(activeModules),
  );
}
