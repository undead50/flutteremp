import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/blur_bar.dart';
import 'package:relay/core/widgets/responsive_body.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// The four top-level destinations, in bar order.
enum RelayTab {
  memos('Memos', AppIcons.navMemos, 20, 20),
  modules('Modules', AppIcons.navModules, 18, 18),
  activity('Activity', AppIcons.navActivity, 16, 20),
  settings('Settings', AppIcons.navSettings, 20.1, 20);

  const RelayTab(this.label, this.icon, this.iconWidth, this.iconHeight);

  final String label;
  final String icon;
  final double iconWidth;
  final double iconHeight;
}

/// Frosted bottom navigation with a lifted "pill" behind the selected tab.
class RelayBottomNav extends StatelessWidget {
  const RelayBottomNav({super.key, required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return BlurBar(
      color: context.palette.background.withValues(alpha: 0.9),
      shadows: AppShadows.bottomBar,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppLayout.navHeight,
          child: ResponsiveBody(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppLayout.screenGutter),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  for (final tab in RelayTab.values)
                    _NavItem(
                      tab: tab,
                      isSelected: tab.index == currentIndex,
                      onTap: () => onSelected(tab.index),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.isSelected, required this.onTap});

  final RelayTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? context.palette.brandContainer : context.palette.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: tab.label,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? context.palette.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.r32),
          boxShadow: isSelected ? AppShadows.navPill : AppShadows.none,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.r32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 20,
                      child: SvgAsset(
                        tab.icon,
                        width: tab.iconWidth,
                        height: tab.iconHeight,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(tab.label, style: AppTypography.caption.copyWith(color: color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
