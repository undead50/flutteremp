import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/error/result.dart';
import 'package:relay/core/security/validators.dart';
import 'package:relay/features/auth/domain/entities/user_profile.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';

enum LoginMethod { credentials, sso, quickUnlock }

@immutable
class LoginState {
  const LoginState({
    this.submitting,
    this.failure,
    this.emailError,
    this.passwordError,
    this.lockedOut = false,
  });

  /// Which sign-in path is in flight (drives per-button spinners).
  final LoginMethod? submitting;

  /// Last failure to show in the banner.
  final Failure? failure;
  final String? emailError;
  final String? passwordError;

  /// Client-side cool-down after repeated failures. This is a UX brake only;
  /// the backend must rate-limit and lock accounts on its own.
  final bool lockedOut;

  bool get isBusy => submitting != null;
}

/// Drives the sign-in form. It never sees or stores the password: the widget
/// passes the text in for a single call and the value is not retained.
class LoginController extends Notifier<LoginState> {
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);

  int _failedAttempts = 0;
  Timer? _lockTimer;

  @override
  LoginState build() {
    ref.onDispose(() => _lockTimer?.cancel());
    return const LoginState();
  }

  void clearFieldError({bool email = false, bool password = false}) {
    if (state.emailError == null && state.passwordError == null && state.failure == null) return;
    state = LoginState(
      submitting: state.submitting,
      lockedOut: state.lockedOut,
      failure: state.lockedOut ? state.failure : null,
      emailError: email ? null : state.emailError,
      passwordError: password ? null : state.passwordError,
    );
  }

  Future<void> submitCredentials({required String email, required String password}) async {
    if (state.isBusy || state.lockedOut) return;

    final emailError = Validators.email(email);
    final passwordError = Validators.password(password);
    if (emailError != null || passwordError != null) {
      state = LoginState(emailError: emailError, passwordError: passwordError);
      return;
    }

    await _run(
      LoginMethod.credentials,
      () => ref.read(signInWithCredentialsProvider)(email: email, password: password),
    );
  }

  Future<void> signInWithSso() async {
    if (state.isBusy || state.lockedOut) return;
    await _run(LoginMethod.sso, () => ref.read(signInWithSsoProvider)());
  }

  Future<void> quickUnlock() async {
    if (state.isBusy || state.lockedOut) return;
    await _run(LoginMethod.quickUnlock, () => ref.read(quickUnlockProvider)());
  }

  /// Keeps this (auto-dispose) controller alive while a request is in flight,
  /// so a sign-in that completes after the user navigated away is still applied.
  Future<void> _run(LoginMethod method, Future<Result<UserProfile>> Function() action) async {
    final link = ref.keepAlive();
    state = LoginState(submitting: method);
    try {
      _handle(await action());
    } finally {
      link.close();
    }
  }

  void _handle(Result<UserProfile> result) {
    switch (result) {
      case Success<UserProfile>(:final value):
        _failedAttempts = 0;
        state = const LoginState();
        ref.read(sessionControllerProvider.notifier).signedIn(value);
      case Err<UserProfile>(:final failure):
        if (failure is InvalidCredentialsFailure && ++_failedAttempts >= maxFailedAttempts) {
          _lock();
          return;
        }
        state = LoginState(failure: failure);
    }
  }

  void _lock() {
    state = const LoginState(failure: RateLimitedFailure(), lockedOut: true);
    _lockTimer?.cancel();
    _lockTimer = Timer(lockoutDuration, () {
      _failedAttempts = 0;
      state = const LoginState();
    });
  }
}

final NotifierProvider<LoginController, LoginState> loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(LoginController.new);
