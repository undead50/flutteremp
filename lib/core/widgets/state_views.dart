import 'package:flutter/material.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_button.dart';

/// Centred spinner announced to screen readers.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        label: label,
        child: const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
      ),
    );
  }
}

/// Friendly, non-technical error with an optional retry. Only ever shows
/// [Failure.message]; never raw exception text.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry, this.title});

  final Failure failure;
  final VoidCallback? onRetry;
  final String? title;

  bool get _offline => failure is NetworkFailure || failure is TimeoutFailure;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: _offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
      iconBackground: context.palette.errorContainer,
      iconColor: context.palette.escalationText,
      title: title ?? (_offline ? "Can't reach Relay" : 'Something went wrong'),
      message: failure.message,
      action: onRetry == null
          ? null
          : RelayButton.tonal(
              label: 'Try again',
              onPressed: onRetry,
              expand: false,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              background: context.palette.surfaceHigh,
            ),
    );
  }
}

/// Nothing to show yet.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconBackground: context.palette.mint,
      iconColor: context.palette.brand,
      title: title,
      message: message,
      action: action,
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, size: 28, color: iconColor),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(title, style: AppTypography.cardTitle, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 8),
            Text(message, style: context.text.body15, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
