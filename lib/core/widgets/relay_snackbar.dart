import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';

enum SnackKind { info, success, error }

/// Floating toast. Pass [bottomInset] on screens with a bottom bar so the toast
/// floats above it.
abstract final class RelaySnackbar {
  static void show(
    BuildContext context,
    String message, {
    SnackKind kind = SnackKind.info,
    double bottomInset = 24,
  }) {
    final palette = context.palette;
    final (background, foreground, icon) = switch (kind) {
      SnackKind.success => (palette.primary, palette.onPrimary, Icons.check_circle_rounded),
      SnackKind.error => (palette.escalationFill, palette.onEscalationFill, Icons.error_rounded),
      SnackKind.info => (palette.inverseSurface, palette.onInverseSurface, Icons.info_rounded),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          // Explicit: `margin` is only legal for floating snack bars, whatever the theme says.
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
          duration: const Duration(seconds: 4),
          content: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: AppTypography.label14.copyWith(color: foreground)),
              ),
            ],
          ),
        ),
      );
  }
}
