import 'package:flutter/material.dart';

import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../providers/recommendations_provider.dart';

/// A self-contained section card for one "because you liked …" group: a
/// two-tier header (an uppercase reason label over the driver titles), the
/// cluster's genres as chips, and a horizontal carousel of recommended titles.
/// Each card shows the predicted personal rating (top-left badge) and the TMDB
/// rating (subtitle). Tapping a card runs [onTap].
class RecommendationRowWidget extends StatefulWidget {
  /// Creates a recommendation row.
  const RecommendationRowWidget({
    required this.eyebrow,
    required this.headline,
    required this.genres,
    required this.items,
    required this.onTap,
    this.ownedIds = const <String>{},
    super.key,
  });

  /// Localized reason label, rendered uppercase above the headline
  /// (e.g. "Because you liked").
  final String eyebrow;

  /// The driver titles this group was learned from (e.g. "Dune, Blade Runner").
  final String headline;

  /// The cluster's defining genres, shown as chips under the headline.
  final List<String> genres;

  /// Items to show.
  final List<RecommendedItem> items;

  /// Engine ids already in a collection — rendered dimmed, checked and
  /// non-interactive so a pick visibly settles in place once it's added.
  final Set<String> ownedIds;

  /// Fired when a card is tapped.
  final void Function(RecommendedItem item) onTap;

  @override
  State<RecommendationRowWidget> createState() =>
      _RecommendationRowWidgetState();
}

class _RecommendationRowWidgetState extends State<RecommendationRowWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 185 : 230;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.eyebrow.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.headline,
                  style: AppTypography.h2.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.genres.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: <Widget>[
                      for (final String genre in widget.genres)
                        _GenreChip(genre),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: rowHeight,
            child: ScrollableRowWithArrows(
              controller: _scrollController,
              height: rowHeight,
              child: ListView.separated(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  4,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (BuildContext context, int index) {
                  final RecommendedItem item = widget.items[index];
                  final bool isMovie = item.mediaType == MediaType.movie;
                  final bool isOwned = widget.ownedIds.contains(item.tasteId);
                  // Wrapper shape stays constant whether or not the item is
                  // owned: toggling Opacity/IgnorePointer structurally would
                  // re-parent the poster and reload its image. Opacity(1.0) is
                  // a no-op paint, so non-owned cards pay nothing.
                  return SizedBox(
                    key: ValueKey<String>(item.tasteId),
                    width: posterWidth,
                    child: Opacity(
                      opacity: isOwned ? 0.45 : 1.0,
                      child: IgnorePointer(
                        ignoring: isOwned,
                        child: MediaPosterCard(
                          variant: compact
                              ? CardVariant.compact
                              : CardVariant.grid,
                          title: item.title,
                          imageUrl: item.posterUrl ?? '',
                          cacheImageType: isMovie
                              ? ImageType.moviePoster
                              : ImageType.tvShowPoster,
                          cacheImageId: item.tmdbId.toString(),
                          mediaType: item.mediaType,
                          year: item.year,
                          // Predicted personal rating in the badge; TMDB rating
                          // in the subtitle.
                          userRating: item.predictedRating,
                          apiRating: item.apiRating,
                          splitRatings: true,
                          // Already added: show the standard in-collection check.
                          isInCollection: isOwned,
                          placeholderIcon: isMovie
                              ? Icons.movie_outlined
                              : Icons.tv_outlined,
                          onTap: () => widget.onTap(item),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A pill chip for one of a row's rationale genres.
class _GenreChip extends StatelessWidget {
  const _GenreChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

/// Centered placeholder for the empty / no-candidates states.
class RecommendationsEmptyState extends StatelessWidget {
  /// Creates an empty-state panel.
  const RecommendationsEmptyState({
    required this.icon,
    required this.title,
    required this.hint,
    super.key,
  });

  /// Leading icon.
  final IconData icon;

  /// Headline.
  final String title;

  /// Secondary explanation.
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 64, color: AppColors.textTertiary.withAlpha(120)),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
