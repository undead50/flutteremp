import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/relay_card.dart';
import 'package:relay/core/widgets/relay_text_field.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/auth/presentation/providers/login_controller.dart';

/// The white "Primary Authentication Form Card": SSO, email/password, Face ID.
/// Purely presentational; the screen owns the controllers and callbacks.
class LoginFormCard extends StatelessWidget {
  const LoginFormCard({
    super.key,
    required this.state,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onSso,
    required this.onQuickUnlock,
    required this.onForgotPassword,
  });

  final LoginState state;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSso;
  final VoidCallback onQuickUnlock;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final busy = state.isBusy;
    final blocked = busy || state.lockedOut;

    return RelayCard(
      padding: const EdgeInsets.all(28),
      radius: AppRadii.r24,
      shadows: AppShadows.level1,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RelayButton.tonal(
              label: 'Single Sign-On (Google / Okta)',
              gap: 12,
              isLoading: state.submitting == LoginMethod.sso,
              onPressed: blocked ? null : onSso,
              leading: const _GoogleBadge(),
            ),
            const SizedBox(height: 6),
            const _OrDivider(),
            const SizedBox(height: 20),
            _FieldLabelRow(
              label: 'Work Email',
              trailing: Text(
                'corp domain',
                style: AppTypography.caption.copyWith(color: context.palette.outline),
              ),
            ),
            const SizedBox(height: 6),
            RelayTextField(
              controller: emailController,
              hint: 'name@company.com',
              semanticLabel: 'Work email',
              prefix: const SvgAsset(AppIcons.loginMail, width: 20, height: 16),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
              errorText: state.emailError,
              enabled: !busy,
              maxLength: 254,
              onChanged: onEmailChanged,
            ),
            const SizedBox(height: 20),
            _FieldLabelRow(
              label: 'Password or Passkey',
              trailing: InkWell(
                onTap: busy ? null : onForgotPassword,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Forgot?',
                    style: AppTypography.caption.copyWith(color: context.palette.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            RelayTextField(
              controller: passwordController,
              hint: '••••••••••••',
              semanticLabel: 'Password or passkey',
              prefix: const SvgAsset(AppIcons.loginLock, width: 16, height: 21),
              prefixInset: 20,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              errorText: state.passwordError,
              enabled: !busy,
              maxLength: 128,
              onChanged: onPasswordChanged,
              onSubmitted: (_) => onSubmit(),
              suffix: Semantics(
                button: true,
                toggled: !obscurePassword,
                label: obscurePassword ? 'Show password' : 'Hide password',
                excludeSemantics: true,
                onTap: onToggleObscure,
                child: InkResponse(
                  onTap: onToggleObscure,
                  radius: 22,
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Center(child: SvgAsset(AppIcons.loginEye, width: 18.33, height: 12.5)),
                  ),
                ),
              ),
            ),
            if (state.failure != null) ...<Widget>[
              const SizedBox(height: 16),
              _ErrorBanner(failure: state.failure!),
            ],
            const SizedBox(height: 24),
            RelayButton(
              label: 'Enter Workplace',
              shadows: AppShadows.level1,
              isLoading: state.submitting == LoginMethod.credentials,
              onPressed: blocked ? null : onSubmit,
              trailing: const SvgAsset(AppIcons.loginArrowRight, width: 12, height: 12),
            ),
            const SizedBox(height: 26),
            RelayButton.tonal(
              label: 'Quick Unlock with Face ID',
              gap: 12,
              isLoading: state.submitting == LoginMethod.quickUnlock,
              onPressed: blocked ? null : onQuickUnlock,
              leading: const SvgAsset(AppIcons.loginFaceId, width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26.34,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.logoTile,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        boxShadow: AppShadows.level1,
      ),
      child: const SvgAsset(AppIcons.loginGoogle, width: 16, height: 16),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: SizedBox(height: 2, child: ColoredBox(color: context.palette.surface)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: <Widget>[
          line,
          const SizedBox(width: 12),
          Text(
            'OR SIGN IN WITH EMAIL',
            style: AppTypography.overline.copyWith(color: context.palette.outline),
          ),
          const SizedBox(width: 12),
          line,
        ],
      ),
    );
  }
}

class _FieldLabelRow extends StatelessWidget {
  const _FieldLabelRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(child: Text(label, style: AppTypography.label14)),
        trailing,
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.errorContainer,
          borderRadius: BorderRadius.circular(AppRadii.r16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, size: 20, color: context.palette.escalationText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  failure.message,
                  style: AppTypography.label14.copyWith(color: context.palette.escalationTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
