import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';

/// Visual 44x24 switch track + thumb. Not interactive on its own: place it in a
/// tappable row (which owns the semantics) or use [RelaySwitch].
class RelaySwitchTrack extends StatelessWidget {
  const RelaySwitchTrack({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: value ? palette.primary : palette.surfaceHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: value ? palette.onPrimary : palette.thumbOff,
          shape: BoxShape.circle,
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}

/// Visual 20x20 checkbox. See [RelaySwitchTrack] for how to make it tappable.
class RelayCheckboxMark extends StatelessWidget {
  const RelayCheckboxMark({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? palette.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: value ? null : Border.all(color: palette.outline, width: 2),
      ),
      child: value ? Icon(Icons.check_rounded, size: 15, color: palette.onPrimaryContainer) : null,
    );
  }
}

/// Standalone switch with a 44x44 hit area.
class RelaySwitch extends StatelessWidget {
  const RelaySwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: RelaySwitchTrack(value: value)),
          ),
        ),
      ),
    );
  }
}

/// Standalone checkbox with a 44x44 hit area.
class RelayCheckbox extends StatelessWidget {
  const RelayCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      checked: value,
      enabled: onChanged != null,
      label: semanticLabel,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: RelayCheckboxMark(value: value)),
          ),
        ),
      ),
    );
  }
}
