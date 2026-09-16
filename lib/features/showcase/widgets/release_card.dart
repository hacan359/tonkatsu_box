import 'dart:math' as math;

import 'package:core/models/image_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/genre_chip.dart';
import '../../../shared/widgets/in_collection_badge.dart';
import '../../../shared/widgets/rating_badge.dart';
import '../models/showcase_item.dart';
import '../providers/showcase_clock_provider.dart';
import '../utils/release_labels.dart';
import '../utils/showcase_cover.dart';

/// Cover left, text right, at a fixed height so the grid never measures a
/// card; only the countdown line listens to the clock.
class ReleaseCard extends StatelessWidget {
  const ReleaseCard({
    required this.item,
    required this.onTap,
    this.isOwned = false,
    super.key,
  });

  final ShowcaseItem item;
  final VoidCallback onTap;
  final bool isOwned;

  static const double _coverWidth = 100;
  static const double _coverWidthCompact = 84;
  static const int _maxGenres = 3;

  /// Past this the cover would outgrow the row; text keeps scaling, the
  /// card height stops.
  static const double _maxTextScaleGrowth = 1.6;

  static double coverWidth({required bool compact}) =>
      compact ? _coverWidthCompact : _coverWidth;

  /// The cover sets the height; larger text gets a taller card so the text
  /// column never has to overflow.
  static double height({
    required bool compact,
    required TextScaler textScaler,
  }) {
    final double base =
        coverWidth(compact: compact) / AppSpacing.posterAspectRatio;
    return base * textScaler.scale(1).clamp(1.0, _maxTextScaleGrowth);
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final Color accent = MediaTypeTheme.colorFor(item.mediaType);
    final String meta = releaseMeta(l, item);
    final String? description = item.description?.trim();
    final double? rating = item.rating;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Cover(item: item, isOwned: isOwned, accent: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        if (rating != null) ...<Widget>[
                          const SizedBox(width: AppSpacing.xs),
                          RatingBadge(rating: rating, compact: true),
                        ],
                      ],
                    ),
                    if (item.nextDate != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      _Countdown(item: item, accent: accent),
                    ],
                    if (meta.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    Expanded(
                      child: description == null || description.isEmpty
                          ? const SizedBox.shrink()
                          : _FittedDescription(text: description),
                    ),
                    if (item.genres.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      _GenreChips(
                        genres: item.genres.take(_maxGenres).toList(),
                        accent: accent,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The only part of the card that rebuilds on the minute tick.
class _Countdown extends ConsumerWidget {
  const _Countdown({required this.item, required this.accent});

  final ShowcaseItem item;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime now = ref.watch(showcaseNowProvider);
    final String? headline = releaseHeadline(S.of(context), item, now);
    if (headline == null) return const SizedBox.shrink();
    final String locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          releaseDateText(item, locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.item,
    required this.isOwned,
    required this.accent,
  });

  final ShowcaseItem item;
  final bool isOwned;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double width = ReleaseCard.coverWidth(
      compact: isCompactScreen(context),
    );
    final ({ImageType type, String id}) cache = showcaseCoverCache(item);
    final Widget placeholder = Container(
      color: AppColors.surfaceLight,
      alignment: Alignment.center,
      child: Icon(
        MediaTypeTheme.placeholderIconFor(item.mediaType),
        color: AppColors.textTertiary,
      ),
    );
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (item.posterUrl case final String url when url.isNotEmpty)
            CachedImage(
              imageType: cache.type,
              imageId: cache.id,
              remoteUrl: url,
              fit: BoxFit.cover,
              placeholder: placeholder,
              errorWidget: placeholder,
            )
          else
            placeholder,
          // A type stripe: the row title says the type, the card repeats it
          // at a glance when day groups mix nothing but still scan faster.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: accent),
          ),
          if (isOwned)
            const Positioned(
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              child: InCollectionBadge(),
            ),
        ],
      ),
    );
  }
}

/// As many lines as the leftover height fits, so the card never overflows
/// and never leaves an awkward half-line.
class _FittedDescription extends StatelessWidget {
  const _FittedDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final TextStyle style =
        AppTypography.caption.copyWith(color: AppColors.textTertiary);
    final double lineHeight = MediaQuery.textScalerOf(context)
        .scale((style.fontSize ?? 12) * (style.height ?? 1.3));
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int lines = (constraints.maxHeight / lineHeight).floor();
        if (lines < 1) return const SizedBox.shrink();
        return Text(
          text,
          maxLines: math.min(lines, 4),
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

/// A single row of pills; whatever does not fit is clipped, not wrapped.
class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.genres, required this.accent});

  final List<String> genres;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: <Widget>[
          for (final String genre in genres)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: GenreChip(genre, accent: accent),
            ),
        ],
      ),
    );
  }
}
