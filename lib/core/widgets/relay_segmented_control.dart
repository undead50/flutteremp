import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';

/// Pill-shaped single-choice selector ("Standard / Large / Extra Large",
/// "System / Light / Dark"). The selected segment is lifted on a card surface.
///
/// Exposed to assistive tech as a mutually exclusive group of buttons.
class RelaySegmentedControl<T> extends StatelessWidget {
  const RelaySegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadii.r24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: <Widget>[
              for (final value in values)
                Expanded(
                  child: _Segment(
                    label: labelOf(value),
                    isSelected: value == selected,
                    onTap: () => onChanged(value),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? palette.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.r20),
          boxShadow: isSelected ? AppShadows.navPill : AppShadows.none,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.r20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.label14.copyWith(
                      color: isSelected ? palette.brand : palette.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
