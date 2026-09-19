import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_theme.dart';
import 'package:relay/core/theme/app_typography.dart';

/// 56pt filled input with an absolutely-positioned leading icon (as in the
/// design), an optional trailing action and an inline, screen-reader-announced
/// error message.
class RelayTextField extends StatelessWidget {
  const RelayTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.semanticLabel,
    this.prefix,
    this.prefixInset = 18,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.height = 56,
  });

  final TextEditingController controller;
  final String hint;

  /// Read by screen readers instead of the (visual-only) hint.
  final String semanticLabel;
  final Widget? prefix;
  final double prefixInset;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final a11y = Theme.of(context).extension<RelayAccessibilityTheme>();
    final hasError = errorText != null;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.r16),
      borderSide: width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
    );

    final resting = hasError
        ? border(context.palette.error, 1.5)
        : (a11y?.highContrast ?? false)
        ? border(context.palette.onSurfaceVariant, 1.5)
        : border(Colors.transparent, 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Semantics(
                  label: semanticLabel,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: enabled,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    // Credentials/personal data: never learn, suggest or auto-correct.
                    autocorrect: false,
                    enableSuggestions: false,
                    enableIMEPersonalizedLearning: false,
                    textAlignVertical: TextAlignVertical.center,
                    style: AppTypography.input,
                    cursorColor: context.palette.brand,
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: AppTypography.input.copyWith(color: context.palette.outline),
                      counterText: '',
                      filled: true,
                      fillColor: context.palette.surfaceLow,
                      contentPadding: EdgeInsets.fromLTRB(
                        prefix == null ? 16 : 48,
                        0,
                        suffix == null ? 16 : 52,
                        0,
                      ),
                      border: resting,
                      enabledBorder: resting,
                      disabledBorder: resting,
                      errorBorder: resting,
                      focusedBorder: border(
                        hasError ? context.palette.error : context.palette.brandContainer,
                        2,
                      ),
                    ),
                  ),
                ),
              ),
              if (prefix != null)
                Positioned(
                  left: prefixInset,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(child: Center(child: prefix)),
                ),
              if (suffix != null)
                Positioned(right: 4, top: 0, bottom: 0, child: Center(child: suffix)),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                style: AppTypography.caption.copyWith(color: context.palette.error),
              ),
            ),
          ),
      ],
    );
  }
}
