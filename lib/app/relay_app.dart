import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/app/router/app_router.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/features/settings/domain/entities/user_preferences.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';

/// Root widget: theme, router and the app-wide appearance/accessibility settings.
class RelayApp extends ConsumerWidget {
  const RelayApp({super.key});

  static ThemeMode themeModeOf(AppearanceMode mode) => switch (mode) {
    AppearanceMode.system => ThemeMode.system,
    AppearanceMode.light => ThemeMode.light,
    AppearanceMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final prefs = ref.watch(preferencesControllerProvider);

    return MaterialApp.router(
      title: 'EBL Relay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(highContrast: prefs.highContrast),
      darkTheme: AppTheme.dark(highContrast: prefs.highContrast),
      // `system` follows the device; light/dark override it.
      themeMode: themeModeOf(prefs.appearance),
      routerConfig: router,
      builder: (context, child) => _SystemBars(
        child: _TextScaleBoundary(
          userScale: prefs.textSize.scale,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Keeps the status/navigation bar icons legible against the active theme.
class _SystemBars extends StatelessWidget {
  const _SystemBars({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final icons = palette.isDark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: palette.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: palette.background,
        systemNavigationBarIconBrightness: icons,
      ),
      child: child,
    );
  }
}

/// Multiplies the OS text scale by the in-app preset (Standard / Large / Extra
/// Large), so both accessibility controls apply, capped to keep layouts intact.
class _TextScaleBoundary extends StatelessWidget {
  const _TextScaleBoundary({required this.userScale, required this.child});

  final double userScale;
  final Widget child;

  static const double _maxScale = 2;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Sample at 14pt so non-linear OS scalers (Android 14+) are respected.
    final system = media.textScaler.scale(14) / 14;
    final combined = (system * userScale).clamp(0.8, _maxScale);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(combined)),
      child: child,
    );
  }
}
