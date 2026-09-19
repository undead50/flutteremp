import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/support_links.dart';
import 'package:relay/features/auth/presentation/providers/login_controller.dart';
import 'package:relay/features/auth/presentation/widgets/login_footer.dart';
import 'package:relay/features/auth/presentation/widgets/login_form_card.dart';
import 'package:relay/features/auth/presentation/widgets/login_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Field text lives in the widget, never in provider state, so the password is
  // not retained anywhere longer than the text field itself.
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(loginControllerProvider.notifier)
        .submitCredentials(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    // A wrong password is cleared so it doesn't linger in the field.
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next.failure is InvalidCredentialsFailure &&
          previous?.failure is! InvalidCredentialsFailure) {
        _password.clear();
      }
    });

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const LoginHeader(),
                const SizedBox(height: 28),
                LoginFormCard(
                  state: state,
                  emailController: _email,
                  passwordController: _password,
                  obscurePassword: _obscure,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onEmailChanged: (_) => controller.clearFieldError(email: true),
                  onPasswordChanged: (_) => controller.clearFieldError(password: true),
                  onSubmit: _submit,
                  onSso: controller.signInWithSso,
                  onQuickUnlock: controller.quickUnlock,
                  onForgotPassword: () => openHelpdesk(context, ref),
                ),
                const SizedBox(height: 20),
                const LoginTrustBadge(),
                const SizedBox(height: 28),
                LoginSupportFooter(onContactIt: () => openHelpdesk(context, ref)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
