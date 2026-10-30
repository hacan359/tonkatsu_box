import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../copyable_text.dart';
import 'detail_sections.dart';
import 'expandable_description.dart';
import 'identity_header.dart';
import 'progress_tiles.dart';
import 'system_meta_info_button.dart';
import 'tracker_comments_layout.dart';
import 'user_rating_section.dart';

/// Phone and narrow-window card: every block in one column on a translucent
/// backing.
class MobileDetailLayout extends StatelessWidget {
  const MobileDetailLayout({required this.sections, super.key});

  final DetailSections sections;

  @override
  Widget build(BuildContext context) {
    // The backing's own padding is the only outer inset, so narrow screens
    // don't lose width to a doubled-up margin.
    // Under a floating app bar the body starts at the top edge, and the
    // query carries the bar's height — the title sits just below it.
    return ListView(
      padding: MediaQuery.paddingOf(context).copyWith(right: 0),
      children: <Widget>[
        // Descendant ListTile/ExpansionTile need a Material ancestor for ink —
        // Flutter 3.44 asserts when a coloured DecoratedBox sits between.
        Material(
          color: AppColors.surface.withAlpha(80),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder.withAlpha(40)),
            ),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final DetailSections s = sections;
    final String? description = s.description;
    final ValueChanged<double?>? onRatingChanged = s.onRatingChanged;
    final DetailProgress? progress = s.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The bar carries no title, so the heading opens the backing itself.
        CopyableText(
          text: s.title,
          child: Text(
            s.title,
            style: AppTypography.h1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IdentityHeader(cover: s.cover, badges: s.badges, infoChips: s.chips),
        if (description != null && description.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ExpandableDescription(text: description),
        ],
        ..._gap(s.tags, AppSpacing.sm),
        ..._gap(s.status, AppSpacing.md),
        if (onRatingChanged != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          UserRatingSection(value: s.rating, onChanged: onRatingChanged),
        ],
        if (progress != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          ProgressTileGrid(
            tiles: <Widget>[
              for (final ProgressFact fact in progress.facts) fact.toTile(),
            ],
            trailing: SystemMetaInfoButton(text: progress.systemMeta),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TrackerCommentsLayout(
          trackerSection: s.tracker,
          notesSection: s.notes,
          authorSection: s.author,
        ),
        ..._gap(s.gallery, AppSpacing.md),
        for (final Widget section in s.extras) ..._gap(section, AppSpacing.md),
        for (final Widget section in s.recommendations)
          ..._gap(section, AppSpacing.md),
      ],
    );
  }

  List<Widget> _gap(Widget? child, double gap) => child == null
      ? const <Widget>[]
      : <Widget>[SizedBox(height: gap), child];
}
