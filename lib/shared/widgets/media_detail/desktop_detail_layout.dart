import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../constants/platform_features.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../copyable_text.dart';
import '../fractional_star_rating.dart';
import 'detail_sections.dart';
import 'expandable_description.dart';
import 'identity_header.dart';
import 'media_detail_backdrop.dart';
import 'media_detail_chip.dart';
import 'progress_tiles.dart';
import '../glass_panel.dart';

/// Below this width a desktop window keeps the mobile column.
const double kDesktopDetailMinWidth = 600;

const double _wideBreakpoint = 1100;

/// Stars sized to fit the side column without shrinking.
const double _starSize = 20;

class _Metrics {
  const _Metrics({
    required this.asideWidth,
    required this.gap,
    required this.padding,
    required this.titleSize,
  });

  final double asideWidth;
  final double gap;
  final EdgeInsets padding;
  final double titleSize;

  // The panel already frames the card, so the outer inset stays small and
  // the aside block (poster plus its padding) gets the room instead.
  static const _Metrics wide = _Metrics(
    asideWidth: 300,
    gap: 32,
    padding: EdgeInsets.fromLTRB(24, 24, 24, 40),
    titleSize: 34,
  );
  static const _Metrics medium = _Metrics(
    asideWidth: 260,
    gap: 24,
    padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
    titleSize: 28,
  );
  static const _Metrics narrow = _Metrics(
    asideWidth: 210,
    gap: 16,
    padding: EdgeInsets.all(16),
    titleSize: 24,
  );

  static _Metrics of(double width) {
    if (width >= _wideBreakpoint) return wide;
    if (width >= kDesktopContentBreakpoint) return medium;
    return narrow;
  }
}

/// Desktop card: poster, rating, status and dates in a left column; the
/// work itself — title, credits, description, notes, sections — on the right.
class DesktopDetailLayout extends StatelessWidget {
  const DesktopDetailLayout({required this.sections, super.key});

  final DetailSections sections;

  /// Keeps description lines near a readable length.
  static const double _descriptionMaxWidth = 760;
  static const int _descriptionLines = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final _Metrics m = _Metrics.of(constraints.maxWidth);
        // The text block fills the window, so a short description does not
        // leave a stub of a tile next to a tall poster column.
        final double minHeight = constraints.maxHeight.isFinite
            ? math.max(0, constraints.maxHeight - m.padding.vertical)
            : 0;
        return SingleChildScrollView(
          padding: m.padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: m.asideWidth, child: _buildAside(context)),
              SizedBox(width: m.gap),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: _buildMain(context, m),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAside(BuildContext context) {
    final DetailSections s = sections;
    final ValueChanged<double?>? onRatingChanged = s.onRatingChanged;
    final DetailProgress? progress = s.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced(<Widget?>[
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -10,
              ),
            ],
          ),
          child: AspectRatio(
            aspectRatio: AppSpacing.posterAspectRatio,
            child: s.cover,
          ),
        ),
        if (onRatingChanged != null)
          GlassTile(
            child: _RatingBlock(value: s.rating, onChanged: onRatingChanged),
          ),
        if (s.statusList != null || s.status != null)
          GlassTile(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: s.statusList ?? s.status!,
          ),
        if (progress != null)
          GlassTile(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final ProgressFact fact in progress.facts)
                  ProgressFactRow(fact: fact),
                ProgressFactRow(fact: progress.added),
              ],
            ),
          ),
      ], AppSpacing.md),
    );
  }

  Widget _buildMain(BuildContext context, _Metrics m) {
    final DetailSections s = sections;
    final List<MediaDetailChip> creators = <MediaDetailChip>[
      for (final MediaDetailChip c in s.chips)
        if (c.isCreator) c,
    ];
    final List<MediaDetailChip> facts = <MediaDetailChip>[
      for (final MediaDetailChip c in s.chips)
        if (!c.isCreator) c,
    ];
    final String? description = s.description;

    final Widget text = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced(<Widget?>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            s.badges,
            const SizedBox(height: 12),
            CopyableText(
              text: s.title,
              child: Text(
                s.title,
                style: AppTypography.h1.copyWith(
                  fontSize: m.titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
        if (creators.isNotEmpty)
          _CreditsRow(creators: creators, color: s.accentColor),
        if (facts.isNotEmpty) InfoChipWrap(chips: facts),
        if (description != null && description.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _descriptionMaxWidth),
              child: ExpandableDescription(
                text: description,
                collapsedLines: _descriptionLines,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
        s.tags,
        s.notes,
        s.author,
        s.tracker,
        ...s.extras,
        s.gallery,
        ...s.recommendations,
      ], AppSpacing.lg),
    );

    // The text floats as one block; the poster column stays on the panel.
    final String? backdropUrl = s.backdropUrl;
    return GlassTile(
      padding: const EdgeInsets.all(AppSpacing.lg),
      background: backdropUrl == null
          ? null
          : MediaDetailBackdrop(imageUrl: backdropUrl),
      child: text,
    );
  }
}

/// Caps label carrying the current value over the star row.
class _RatingBlock extends StatelessWidget {
  const _RatingBlock({required this.value, required this.onChanged});

  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final double? value = this.value;
    final String label = l.detailMyRating.toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value == null
              ? label
              : '$label · ${l.detailRatingValue(value.toStringAsFixed(1))}',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        FractionalStarRating(
          value: value,
          onChanged: onChanged,
          starSize: _starSize,
        ),
      ],
    );
  }
}

/// Credits grouped by role: a small caps label over the names, each name
/// opening the same search its header chip does.
class _CreditsRow extends StatelessWidget {
  const _CreditsRow({required this.creators, required this.color});

  final List<MediaDetailChip> creators;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Map<String, List<MediaDetailChip>> byRole =
        <String, List<MediaDetailChip>>{};
    for (final MediaDetailChip c in creators) {
      byRole.putIfAbsent(c.tooltip ?? '', () => <MediaDetailChip>[]).add(c);
    }
    return Wrap(
      spacing: 28,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final MapEntry<String, List<MediaDetailChip>> role
            in byRole.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (role.key.isNotEmpty)
                Text(
                  role.key.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                  ),
                ),
              const SizedBox(height: 2),
              Wrap(
                children: <Widget>[
                  for (int i = 0; i < role.value.length; i++)
                    _CreditName(
                      chip: role.value[i],
                      color: color,
                      trailingComma: i < role.value.length - 1,
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _CreditName extends StatelessWidget {
  const _CreditName({
    required this.chip,
    required this.color,
    required this.trailingComma,
  });

  final MediaDetailChip chip;
  final Color color;
  final bool trailingComma;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.bodySmall.copyWith(
      color: color,
      fontWeight: FontWeight.w500,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: chip.onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          child: Text(chip.text, style: style),
        ),
        if (trailingComma)
          Text(', ', style: style.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}

/// Inserts [gap] between [children]; null children are dropped.
List<Widget> _spaced(List<Widget?> children, double gap) {
  final List<Widget> out = <Widget>[];
  for (final Widget? child in children) {
    if (child == null) continue;
    if (out.isNotEmpty) out.add(SizedBox(height: gap));
    out.add(child);
  }
  return out;
}
