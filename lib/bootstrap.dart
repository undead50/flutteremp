import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/app/relay_app.dart';
import 'package:relay/core/config/app_config.dart';
import 'package:relay/core/logging/app_logger.dart';
import 'package:relay/core/providers/core_providers.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Validates configuration, installs safe global error handling and starts the
/// app. Fails *closed*: an invalid or missing configuration shows an error
/// screen instead of running with insecure defaults.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = AppConfig.fromEnvironment();
  } on ConfigurationException catch (e) {
    runApp(_ConfigurationErrorApp(detail: kReleaseMode ? null : e.message));
    return;
  }

  _installErrorHandlers(AppLogger(verbose: config.enableLogging));
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Failed loads show an error state with a manual retry; no silent
      // exponential re-tries against the backend.
      retry: (retryCount, error) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RelayApp(),
    ),
  );
}

void _installErrorHandlers(AppLogger logger) {
  FlutterError.onError = (details) {
    logger.error('Flutter framework error', error: details.exception, stackTrace: details.stack);
    if (!kReleaseMode) FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };
  // Never paint exception text or stack traces into the UI in release builds.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _FriendlyErrorWidget();
  }
}

class _FriendlyErrorWidget extends StatelessWidget {
  const _FriendlyErrorWidget();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.background,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Something went wrong. Please go back and try again.',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp({this.detail});

  final String? detail;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Relay is not configured',
                    style: AppTypography.headline,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail ?? 'This build is missing required configuration. Please reinstall or contact support.',
                    style: context.text.body15,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
