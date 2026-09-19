import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_button.dart';
import 'package:relay/core/widgets/relay_dialogs.dart';
import 'package:relay/core/widgets/relay_headers.dart';
import 'package:relay/core/widgets/relay_snackbar.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/features/auth/presentation/providers/auth_providers.dart';
import 'package:relay/features/settings/presentation/providers/settings_providers.dart';
import 'package:relay/features/settings/presentation/widgets/settings_appearance_card.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';
import 'package:relay/features/settings/presentation/widgets/settings_modules_card.dart';
import 'package:relay/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:relay/features/settings/presentation/widgets/settings_proxy_card.dart';
import 'package:relay/features/settings/presentation/widgets/settings_tactile_card.dart';
import 'package:relay/features/settings/presentation/widgets/settings_text_size_card.dart';

/// Settings tab: profile, readability, tactile/contrast, modules, proxy and
/// session actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const double _toastInset = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final prefs = ref.watch(preferencesControllerProvider);
    final prefsController = ref.read(preferencesControllerProvider.notifier);
    final proxy = ref.watch(signOffProxyProvider);
    final outbox = ref.watch(outboxCountProvider);
    final syncing = ref.watch(outboxSyncControllerProvider);

    final viewPadding = MediaQuery.viewPaddingOf(context);
    final topInset = viewPadding.top + AppLayout.headerHeight;
    final bottomInset = viewPadding.bottom + AppLayout.navHeight + 32;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ResponsiveBody(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, topInset, 20, bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: <Widget>[
                    if (user != null) SettingsProfileCard(user: user),
                    SettingsAppearanceCard(
                      selected: prefs.appearance,
                      onSelected: prefsController.setAppearance,
                    ),
                    SettingsTextSizeCard(
                      selected: prefs.textSize,
                      onSelected: prefsController.setTextSize,
                    ),
                    SettingsTactileCard(
                      preferences: prefs,
                      onHaptic: (v) => prefsController.setHapticOnApproval(enabled: v),
                      onHighContrast: (v) => prefsController.setHighContrast(enabled: v),
                      onBiometric: (v) => prefsController.setBiometricRecheck(enabled: v),
                    ),
                    SettingsModulesCard(
                      activeModules: prefs.activeModules,
                      onToggle: (module, {required enabled}) async {
                        final failure = await prefsController.setModule(module, enabled: enabled);
                        if (failure != null && context.mounted) {
                          RelaySnackbar.show(
                            context,
                            failure.message,
                            kind: SnackKind.error,
                            bottomInset: _toastInset,
                          );
                        }
                      },
                    ),
                    SettingsProxyCard(
                      proxy: proxy,
                      onRetry: () => ref.invalidate(signOffProxyProvider),
                      onConfigure: () => showRelayInfoDialog(
                        context,
                        title: 'Sign-off proxy',
                        message:
                            'Delegation is granted and revoked by your administrator. '
                            'Contact IT Operations to change who can sign on your behalf.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: <Widget>[
                          RelayButton.tonal(
                            label: outbox.hasValue
                                ? 'Synchronize Offline Outbox (${outbox.requireValue})'
                                : 'Synchronize Offline Outbox',
                            height: 54,
                            radius: AppRadii.pill,
                            background: context.palette.surfaceHigh,
                            isLoading: syncing,
                            onPressed: syncing ? null : () => _sync(context, ref),
                            leading: Icon(
                              SettingsIcons.sync,
                              size: 18,
                              color: context.palette.onSurface,
                            ),
                          ),
                          RelayButton(
                            label: 'Sign Out of Relay Workstation',
                            height: 54,
                            radius: AppRadii.pill,
                            background: context.palette.errorContainer,
                            foreground: context.palette.error,
                            onPressed: () => _confirmSignOut(context, ref),
                            leading: Icon(
                              SettingsIcons.signOut,
                              size: 18,
                              color: context.palette.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Relay Enterprise · Build 4.19.0 (Apple Silicon Optimized)',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(color: context.palette.outline),
                          ),
                          Text(
                            'Encrypted End-to-End via Relay Ledger',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(color: context.palette.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RelayBrandHeader(
              title: 'Settings',
              avatarSource: user?.avatar,
              userName: user?.displayName ?? '',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(outboxSyncControllerProvider.notifier).sync();
    if (!context.mounted) return;
    result.when(
      success: (delivered) => RelaySnackbar.show(
        context,
        delivered == 0 ? 'Your outbox is up to date.' : 'Synchronized $delivered pending item(s).',
        kind: SnackKind.success,
        bottomInset: _toastInset,
      ),
      failure: (failure) => RelaySnackbar.show(
        context,
        failure.message,
        kind: SnackKind.error,
        bottomInset: _toastInset,
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showRelayConfirmDialog(
      context,
      title: 'Sign out of Relay?',
      message: 'You will need to sign in again to review and approve memos on this device.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(sessionControllerProvider.notifier).signOut();
  }
}
