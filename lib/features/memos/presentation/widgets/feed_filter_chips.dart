import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/svg_asset.dart';
import 'package:relay/features/memos/domain/entities/memo_feed.dart';

/// Horizontally scrolling filter row: Memos / Budgets / Leave / Policies.
class FeedFilterChips extends StatelessWidget {
  const FeedFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.countOf,
    required this.onSelected,
  });

  final List<FeedFilter> filters;
  final FeedFilter selected;
  final int Function(FeedFilter filter) countOf;
  final ValueChanged<FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Center(
            child: _FilterChip(
              filter: filter,
              count: countOf(filter),
              isSelected: filter == selected,
              onTap: () => onSelected(filter),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final FeedFilter filter;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  static String labelOf(FeedFilter filter) => switch (filter) {
    FeedFilter.all => 'Memos',
    FeedFilter.budgets => 'Budgets',
    FeedFilter.leave => 'Leave',
    FeedFilter.policies => 'Policies',
  };

  (String, double, double) get _icon => switch (filter) {
    FeedFilter.all => (AppIcons.feedTabMemos, 15, 13.5),
    FeedFilter.budgets => (AppIcons.feedTabBudgets, 14.25, 13.5),
    FeedFilter.leave => (AppIcons.feedTabLeave, 13.5, 15),
    FeedFilter.policies => (AppIcons.feedTabPolicies, 12, 15),
  };

  @override
  Widget build(BuildContext context) {
    final label = labelOf(filter);
    final (icon, iconW, iconH) = _icon;
    final foreground = isSelected ? context.palette.brand : context.palette.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: '$label, $count',
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? context.palette.card : context.palette.surfaceHigh,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: isSelected ? AppShadows.chipLift : AppShadows.none,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SvgAsset(icon, width: iconW, height: iconH),
                  const SizedBox(width: 8),
                  Text(label, style: AppTypography.label14.copyWith(color: foreground)),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? context.palette.primary : context.palette.surfaceHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.counter.copyWith(
                        color: isSelected
                            ? context.palette.onPrimary
                            : context.palette.onSurfaceVariant,
                        height: 1,
                      ),
                    ),
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
