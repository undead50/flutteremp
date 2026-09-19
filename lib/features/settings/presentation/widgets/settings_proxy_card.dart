import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:relay/core/error/failure.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/features/settings/domain/entities/sign_off_proxy.dart';
import 'package:relay/features/settings/presentation/widgets/settings_common.dart';

/// "Sign-off Proxy": who may sign on the user's behalf, with loading, empty
/// and error states for the (remote) proxy lookup.
class SettingsProxyCard extends StatelessWidget {
  const SettingsProxyCard({
    super.key,
    required this.proxy,
    required this.onConfigure,
    required this.onRetry,
  });

  final AsyncValue<SignOffProxy?> proxy;
  final VoidCallback onConfigure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SettingsSectionCard(
      children: <Widget>[
        SettingsCardHeader(
          icon: SettingsIcons.proxy,
          title: 'Sign-off Proxy',
          subtitle: 'Temporarily delegate signing powers',
          iconBackground: context.palette.peach,
          iconForeground: context.palette.secondary,
        ),
        switch (proxy) {
          AsyncData<SignOffProxy?>(:final value?) => _ProxyTile(
            proxy: value,
            onConfigure: onConfigure,
          ),
          AsyncData<SignOffProxy?>() => _MessageTile(
            message: 'No proxy is set up.',
            actionLabel: 'Configure',
            onAction: onConfigure,
          ),
          AsyncError<SignOffProxy?>(:final error) => _MessageTile(
            message: error is AppException ? error.failure.message : const UnknownFailure().message,
            actionLabel: 'Retry',
            onAction: onRetry,
          ),
          _ => const _LoadingTile(),
        },
      ],
    );
  }
}

class _ProxyTile extends StatelessWidget {
  const _ProxyTile({required this.proxy, required this.onConfigure});

  final SignOffProxy proxy;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadii.r24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            RelayAvatar(source: proxy.avatar, name: proxy.name, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(proxy.name, style: AppTypography.label14),
                  Text(
                    proxy.statusLabel,
                    style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PillAction(
              label: 'Configure',
              semanticLabel: 'Configure proxy for ${proxy.name}',
              onTap: onConfigure,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.actionLabel, required this.onAction});

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadii.r24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  message,
                  style: AppTypography.caption.copyWith(color: context.palette.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PillAction(label: actionLabel, semanticLabel: actionLabel, onTap: onAction),
          ],
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Loading proxy',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surfaceLow,
          borderRadius: BorderRadius.circular(AppRadii.r24),
        ),
        child: const SizedBox(
          height: 60,
          child: Center(
            child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({required this.label, required this.semanticLabel, required this.onTap});

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: semanticLabel,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: AppShadows.level1,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(color: context.palette.brand),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
