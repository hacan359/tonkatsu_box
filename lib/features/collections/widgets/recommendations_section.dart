import '../../../shared/constants/platform_features.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../providers/collections_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../../search/widgets/item_details_sheet.dart';
import '../../settings/providers/settings_provider.dart' show SettingsState, settingsNotifierProvider;

FutureProvider<List<Movie>> _createMovieRecProvider(int tmdbId) =>
    FutureProvider<List<Movie>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getMovieRecommendations(tmdbId);
    });

FutureProvider<List<TvShow>> _createTvRecProvider(int tmdbId) =>
    FutureProvider<List<TvShow>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getTvRecommendations(tmdbId);
    });

/// Providers are cached per tmdbId so rebuilding the widget does not
/// re-fetch recommendations.
final Map<int, FutureProvider<List<Movie>>> _movieRecProviders =
    <int, FutureProvider<List<Movie>>>{};

final Map<int, FutureProvider<List<TvShow>>> _tvRecProviders =
    <int, FutureProvider<List<TvShow>>>{};

FutureProvider<List<Movie>> _getMovieRecProvider(int tmdbId) {
  return _movieRecProviders.putIfAbsent(
    tmdbId,
    () => _createMovieRecProvider(tmdbId),
  );
}

FutureProvider<List<TvShow>> _getTvRecProvider(int tmdbId) {
  return _tvRecProviders.putIfAbsent(
    tmdbId,
    () => _createTvRecProvider(tmdbId),
  );
}

/// TMDB-backed recommendations; not shown for games.
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({
    required this.tmdbId,
    required this.mediaType,
    this.onAddMovie,
    this.onAddTvShow,
    super.key,
  });

  final int tmdbId;

  final MediaType mediaType;

  final void Function(Movie movie)? onAddMovie;

  final void Function(TvShow tvShow)? onAddTvShow;

  bool get _isTvBased =>
      mediaType == MediaType.tvShow ||
      (mediaType == MediaType.animation);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsNotifierProvider);
    if (settings.tmdbApiKey == null || settings.tmdbApiKey!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isTvBased) {
      return _buildTvRecommendations(context, ref);
    }
    return _buildMovieRecommendations(context, ref);
  }

  Widget _buildMovieRecommendations(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Movie>> asyncRecs =
        ref.watch(_getMovieRecProvider(tmdbId));

    final Set<int> ownedIds = <int>{
      ...ref.watch(collectedMovieIdsProvider).valueOrNull?.keys ?? <int>[],
      ...ref.watch(collectedAnimationIdsProvider).valueOrNull?.keys ?? <int>[],
    };

    return asyncRecs.when(
      data: (List<Movie> movies) {
        if (movies.isEmpty) return const SizedBox.shrink();
        return _RecommendationRow(
          title: S.of(context).recommendationsTitle,
          items: movies
              .map(
                (Movie m) => _RecItem(
                  title: m.title,
                  posterUrl: m.posterUrl,
                  year: m.releaseYear,
                  apiRating: m.rating,
                  icon: Icons.movie_outlined,
                  cacheImageType: ImageType.moviePoster,
                  cacheImageId: m.tmdbId.toString(),
                  onAddToCollection: () => _showMovieDetails(context, m),
                  isOwned: ownedIds.contains(m.tmdbId),
                ),
              )
              .toList(),
        );
      },
      loading: () => const _RecommendationShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTvRecommendations(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TvShow>> asyncRecs =
        ref.watch(_getTvRecProvider(tmdbId));

    final Set<int> ownedIds = <int>{
      ...ref.watch(collectedTvShowIdsProvider).valueOrNull?.keys ?? <int>[],
      ...ref.watch(collectedAnimationIdsProvider).valueOrNull?.keys ?? <int>[],
    };

    return asyncRecs.when(
      data: (List<TvShow> shows) {
        if (shows.isEmpty) return const SizedBox.shrink();
        return _RecommendationRow(
          title: S.of(context).recommendationsTitle,
          items: shows
              .map(
                (TvShow s) => _RecItem(
                  title: s.title,
                  posterUrl: s.posterUrl,
                  year: s.firstAirYear,
                  apiRating: s.rating,
                  icon: Icons.tv_outlined,
                  cacheImageType: ImageType.tvShowPoster,
                  cacheImageId: s.tmdbId.toString(),
                  onAddToCollection: () => _showTvShowDetails(context, s),
                  isOwned: ownedIds.contains(s.tmdbId),
                ),
              )
              .toList(),
        );
      },
      loading: () => const _RecommendationShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showMovieDetails(BuildContext context, Movie movie) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.movie(
        movie,
        onAddToCollection:
            onAddMovie != null ? () => onAddMovie!(movie) : null,
      ),
    );
  }

  void _showTvShowDetails(BuildContext context, TvShow tvShow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.tvShow(
        tvShow,
        onAddToCollection:
            onAddTvShow != null ? () => onAddTvShow!(tvShow) : null,
      ),
    );
  }
}

class _RecItem {
  const _RecItem({
    required this.title,
    required this.icon,
    required this.onAddToCollection,
    required this.cacheImageType,
    required this.cacheImageId,
    this.posterUrl,
    this.year,
    this.apiRating,
    this.isOwned = false,
  });

  final String title;
  final String? posterUrl;
  final int? year;
  final IconData icon;
  final VoidCallback onAddToCollection;
  final bool isOwned;
  final double? apiRating;
  final ImageType cacheImageType;
  final String cacheImageId;
}

class _RecommendationRow extends StatefulWidget {
  const _RecommendationRow({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_RecItem> items;

  @override
  State<_RecommendationRow> createState() => _RecommendationRowState();
}

class _RecommendationRowState extends State<_RecommendationRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 185 : 230;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ScrollableRowWithArrows(
            controller: _scrollController,
            height: rowHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final _RecItem item = widget.items[index];
                return SizedBox(
                  width: posterWidth,
                  child: MediaPosterCard(
                    variant: compact
                        ? CardVariant.compact
                        : CardVariant.grid,
                    title: item.title,
                    imageUrl: item.posterUrl ?? '',
                    cacheImageType: item.cacheImageType,
                    cacheImageId: item.cacheImageId,
                    year: item.year,
                    apiRating: item.apiRating,
                    splitRatings: true,
                    isInCollection: item.isOwned,
                    placeholderIcon: item.icon,
                    onTap: item.onAddToCollection,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationShimmer extends StatelessWidget {
  const _RecommendationShimmer();

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 175 : 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, _) => SizedBox(
              width: posterWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: posterWidth * 0.7,
                    height: 12,
                    color: AppColors.surfaceLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
