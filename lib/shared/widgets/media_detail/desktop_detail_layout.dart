import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../constants/platform_features.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../fractional_star_rating.dart';
import 'detail_sections.dart';
import 'expandable_description.dart';
import 'identity_header.dart';
import 'media_detail_chip.dart';
import 'progress_tiles.dart';

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

  static const _Metrics wide = _Metrics(
    asideWidth: 260,
    gap: 36,
    padding: EdgeInsets.fromLTRB(40, 32, 40, 48),
    titleSize: 34,
  );
  static const _Metrics medium = _Metrics(
    asideWidth: 220,
    gap: 28,
    padding: EdgeInsets.fromLTRB(28, 28, 28, 40),
    titleSize: 28,
  );
  static const _Metrics narrow = _Metrics(
    asideWidth: 170,
    gap: 20,
    padding: EdgeInsets.all(20),
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
        // Floating bars report their height through the query: the card's
        // own at the top, the nav capsule at the bottom.
        final EdgeInsets inset = MediaQuery.paddingOf(context);
        return SingleChildScrollView(
          padding: m.padding.copyWith(
            left: m.padding.left + inset.left,
            top: m.padding.top + inset.top,
            bottom: m.padding.bottom + inset.bottom,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: m.asideWidth, child: _buildAside()),
              SizedBox(width: m.gap),
              Expanded(child: _buildMain(m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAside() {
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
          _RatingBlock(value: s.rating, onChanged: onRatingChanged),
        s.statusList ?? s.status,
        if (progress != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final ProgressFact fact in progress.facts)
                ProgressFactRow(fact: fact),
              ProgressFactRow(fact: progress.added),
            ],
          ),
      ], AppSpacing.md),
    );
  }

  Widget _buildMain(_Metrics m) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _spaced(<Widget?>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            s.badges,
            const SizedBox(height: 12),
            Text(
              s.title,
              style: AppTypography.h1.copyWith(
                fontSize: m.titleSize,
                fontWeight: FontWeight.w800,
                height: 1.15,
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
              constraints:
                  const BoxConstraints(maxWidth: _descriptionMaxWidth),
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
        s.tracker,
        ...s.extras,
        s.gallery,
        ...s.recommendations,
      ], AppSpacing.lg),
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
