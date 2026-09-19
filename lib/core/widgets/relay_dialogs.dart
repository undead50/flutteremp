import 'package:flutter/material.dart';
import 'package:relay/core/security/input_sanitizer.dart';
import 'package:relay/core/security/validators.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_button.dart';

/// Yes/no confirmation. Resolves to `true` only when the user confirms.
Future<bool> showRelayConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _DialogShell(
      title: title,
      message: message,
      actions: <Widget>[
        RelayButton.tonal(
          label: cancelLabel,
          height: 48,
          background: context.palette.surfaceHigh,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        RelayButton(
          label: confirmLabel,
          height: 48,
          background: destructive ? context.palette.errorFill : context.palette.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single-button information dialog.
Future<void> showRelayInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String closeLabel = 'Got it',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _DialogShell(
      title: title,
      message: message,
      actions: <Widget>[
        RelayButton(label: closeLabel, height: 48, onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}

/// Asks for a short written note (used when requesting a revision or
/// declining). Resolves to the sanitised note, or `null` if cancelled.
Future<String?> showRelayFeedbackDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String hint,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _FeedbackDialog(
      title: title,
      message: message,
      hint: hint,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.message,
    required this.actions,
    this.body,
  });

  final String title;
  final String message;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.palette.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.r28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(header: true, child: Text(title, style: AppTypography.cardTitle)),
              const SizedBox(height: 8),
              Text(message, style: context.text.body15),
              if (body != null) ...<Widget>[const SizedBox(height: 16), body!],
              const SizedBox(height: 24),
              for (var i = 0; i < actions.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackDialog extends StatefulWidget {
  const _FeedbackDialog({
    required this.title,
    required this.message,
    required this.hint,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String hint;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = Validators.feedbackComment(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context)
        .pop(InputSanitizer.multiLine(_controller.text, maxLength: Validators.maxCommentLength));
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.title,
      message: widget.message,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            maxLength: Validators.maxCommentLength,
            textCapitalization: TextCapitalization.sentences,
            style: context.text.body15.copyWith(color: context.palette.onSurface),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: context.text.body15.copyWith(color: context.palette.outline),
              filled: true,
              fillColor: context.palette.surfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.r16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.r16),
                borderSide: BorderSide(color: context.palette.brandContainer, width: 2),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: context.palette.error),
                ),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        RelayButton.tonal(
          label: 'Cancel',
          height: 48,
          background: context.palette.surfaceHigh,
          onPressed: () => Navigator.of(context).pop(),
        ),
        RelayButton(
          label: widget.confirmLabel,
          height: 48,
          background: widget.destructive ? context.palette.errorFill : context.palette.primary,
          onPressed: _submit,
        ),
      ],
    );
  }
}
