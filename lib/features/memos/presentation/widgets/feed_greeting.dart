import 'package:flutter/material.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/utils/formatters.dart';
import 'package:relay/core/widgets/relay_pill.dart';

/// "DAILY BRIEFING · date", greeting and the pending-count sentence.
class FeedGreeting extends StatelessWidget {
  const FeedGreeting({
    super.key,
    required this.firstName,
    required this.now,
    required this.criticalCount,
    required this.deadline,
  });

  final String firstName;
  final DateTime now;
  final int criticalCount;
  final DateTime deadline;

  static String greetingFor(DateTime time) {
    if (time.hour < 12) return 'Good morning';
    if (time.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _summary {
    if (criticalCount == 0) return "Nothing is waiting on your sign-off. You're all caught up.";
    final noun = criticalCount == 1 ? 'memo awaits' : 'memos await';
    return '$criticalCount critical $noun your executive sign-off before ${Formatters.clockTime(deadline)}.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  SizedBox.square(
                    dimension: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.palette.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DAILY BRIEFING',
                    style: AppTypography.overline.copyWith(color: context.palette.secondary),
                  ),
                ],
              ),
              RelayPill(
                label: Formatters.shortDate(now),
                background: context.palette.surface,
                foreground: context.palette.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text('${greetingFor(now)}, $firstName', style: AppTypography.headlineGreeting),
          ),
          const SizedBox(height: 4),
          Text(_summary, style: context.text.body15),
        ],
      ),
    );
  }
}
