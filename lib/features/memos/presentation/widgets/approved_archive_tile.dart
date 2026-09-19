import 'package:flutter/material.dart';
import 'package:relay/core/assets/app_assets.dart';
import 'package:relay/core/theme/app_palette.dart';
import 'package:relay/core/theme/app_metrics.dart';
import 'package:relay/core/theme/app_typography.dart';
import 'package:relay/core/widgets/svg_asset.dart';

/// "18 Approved - Archived in audit vault this month" with a go-to arrow.
class ApprovedArchiveTile extends StatelessWidget {
  const ApprovedArchiveTile({super.key, required this.count, required this.onOpen});

  final int count;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.palette.card,
                    borderRadius: BorderRadius.circular(AppRadii.r16),
                    boxShadow: AppShadows.level1,
                  ),
                  child: const SvgAsset(AppIcons.feedArchive, width: 17.875, height: 14.67),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('$count Approved', style: AppTypography.stat20),
                      Text('Archived in audit vault this month', style: context.text.body15),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            excludeSemantics: true,
            label: 'Open approved memos',
            onTap: onOpen,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.card,
                shape: BoxShape.circle,
                boxShadow: AppShadows.level1,
              ),
              child: InkResponse(
                onTap: onOpen,
                radius: 24,
                child: const SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: SvgAsset(AppIcons.feedArrowRight, width: 13.33, height: 13.33),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
