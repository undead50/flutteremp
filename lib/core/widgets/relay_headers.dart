import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/blur_bar.dart';
import 'package:relay/core/widgets/relay_avatar.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// Frosted 64pt header pinned above scrolling content. Sits *over* the list;
/// screens pad their content by `AppLayout.headerHeight` + the status bar.
class _HeaderFrame extends StatelessWidget {
  const _HeaderFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlurBar(
      color: context.palette.background.withValues(alpha: 0.85),
      shadows: AppShadows.header,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppLayout.headerHeight,
          child: ResponsiveBody(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.screenGutter),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Header for tab screens: emblem + "RELAY / <title>", search and profile.
class RelayBrandHeader extends StatelessWidget {
  const RelayBrandHeader({
    super.key,
    required this.title,
    required this.avatarSource,
    required this.userName,
    this.onSearch,
    this.onProfile,
  });

  final String title;
  final String? avatarSource;
  final String userName;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return _HeaderFrame(
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Image.asset(AppImages.appEmblem, width: 32, height: 32, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: Text(
                    'RELAY',
                    style: AppTypography.overline.copyWith(color: context.palette.brand, height: 1),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline.copyWith(height: 27.5 / 22),
                  ),
                ),
              ],
            ),
          ),
          _IconCircleButton(
            semanticLabel: 'Search memos',
            onTap: onSearch,
            child: const SvgAsset(AppIcons.headerSearch, width: 16.5, height: 16.5),
          ),
          const SizedBox(width: 6),
          _ProfileButton(source: avatarSource, name: userName, onTap: onProfile),
        ],
      ),
    );
  }
}

/// Header for pushed detail screens: back, emblem, title, profile.
class RelayDetailHeader extends StatelessWidget {
  const RelayDetailHeader({
    super.key,
    required this.title,
    required this.onBack,
    required this.avatarSource,
    required this.userName,
  });

  final String title;
  final VoidCallback onBack;
  final String? avatarSource;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return _HeaderFrame(
      child: Row(
        children: <Widget>[
          // 44pt touch target that visually hangs 8pt into the gutter, so the
          // arrow lines up with the 20pt content edge (36pt layout slot).
          SizedBox(
            width: 36,
            height: 44,
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 44,
              maxWidth: 44,
              child: Transform.translate(
                offset: const Offset(-8, 0),
                child: _IconCircleButton(
                  semanticLabel: 'Go back',
                  onTap: onBack,
                  child: const SvgAsset(AppIcons.detailBack, width: 16, height: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ExcludeSemantics(
            child: Image.asset(AppImages.appEmblemDetail, width: 28, height: 28, fit: BoxFit.cover),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headline.copyWith(height: 27.5 / 22),
              ),
            ),
          ),
          RelayAvatar(
            source: avatarSource,
            name: userName,
            size: 32,
            semanticLabel: 'Your profile picture',
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.semanticLabel, required this.child, this.onTap});

  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(dimension: 44, child: Center(child: child)),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.source, required this.name, this.onTap});

  final String? source;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.avatarRing,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: RelayAvatar(source: source, name: name, size: 32),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
