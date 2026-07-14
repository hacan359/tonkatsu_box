import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Splits tracker + notes + author comment into a two-column layout (50/50)
/// on screens ≥600px when [trackerSection] is set, stacks otherwise.
class TrackerCommentsLayout extends StatelessWidget {
  const TrackerCommentsLayout({
    required this.trackerSection,
    required this.notesSection,
    required this.authorSection,
    super.key,
  });

  final Widget? trackerSection;
  final Widget notesSection;
  final Widget authorSection;

  @override
  Widget build(BuildContext context) {
    final Widget commentsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        notesSection,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(
            color: AppColors.surfaceBorder.withAlpha(80),
            height: 1,
          ),
        ),
        authorSection,
      ],
    );

    if (trackerSection == null) return commentsColumn;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= 600) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: trackerSection!),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: commentsColumn),
              ],
            ),
          );
        }
        // Narrow window — stack vertically.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            trackerSection!,
            const SizedBox(height: AppSpacing.md),
            commentsColumn,
          ],
        );
      },
    );
  }
}
