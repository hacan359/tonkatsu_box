import '../../../shared/constants/platform_features.dart';
// Лента подборок Discover (показывается при пустом поиске).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../collections/providers/collections_provider.dart';
import '../providers/discover_provider.dart';
import 'discover_row.dart';
import 'media_details_sheet.dart';

/// Провайдер множества TMDB ID элементов в коллекциях (фильмы + сериалы + анимация).
final FutureProvider<Set<int>> _existingTmdbIdsProvider =
    FutureProvider<Set<int>>((Ref ref) async {
  final Map<int, List<CollectedItemInfo>> movies =
      await ref.watch(collectedMovieIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> tvShows =
      await ref.watch(collectedTvShowIdsProvider.future);
  final Map<int, List<CollectedItemInfo>> animations =
      await ref.watch(collectedAnimationIdsProvider.future);
  return <int>{...movies.keys, ...tvShows.keys, ...animations.keys};
});

/// Лента подборок Discover.
///
/// Показывается на экране поиска когда поле поиска пустое.
/// Фильтрует секции по текущему [sourceId].
class DiscoverFeed extends ConsumerWidget {
  /// Создаёт [DiscoverFeed].
  const DiscoverFeed({
    required this.sourceId,
    required this.onAddMovie,
    required this.onAddTvShow,
    super.key,
  });

  /// ID текущего источника (movies, tv, anime).
  final String sourceId;

  /// Callback добавления фильма в коллекцию.
  final void Function(Movie movie) onAddMovie;

  /// Callback добавления сериала в коллекцию.
  final void Function(TvShow tvShow) onAddTvShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final DiscoverSettings settings = ref.watch(discoverSettingsProvider);
    final Set<int> ownedIds =
        ref.watch(_existingTmdbIdsProvider).valueOrNull ?? <int>{};

    // Секции, доступные для текущей вкладки
    final Set<DiscoverSectionId> available =
        discoverSectionsPerSource[sourceId] ?? <DiscoverSectionId>{};

    final List<Widget> sections = <Widget>[];

    if (available.contains(DiscoverSectionId.trending) &&
        settings.enabledSections.contains(DiscoverSectionId.trending)) {
      sections.add(
        _buildTrendingSection(context, ref, l, ownedIds, settings),
      );
    }

    if (available.contains(DiscoverSectionId.topRatedMovies) &&
        settings.enabledSections.contains(DiscoverSectionId.topRatedMovies)) {
      sections.add(
        _buildMovieSection(
          context,
          ref,
          title: l.discoverTopRatedMovies,
          icon: Icons.star,
          provider: discoverTopRatedMoviesProvider,
          ownedIds: ownedIds,
          settings: settings,
        ),
      );
    }

    if (available.contains(DiscoverSectionId.popularTvShows) &&
        settings.enabledSections.contains(DiscoverSectionId.popularTvShows)) {
      sections.add(
        _buildTvShowSection(
          context,
          ref,
          title: l.discoverPopularTvShows,
          icon: Icons.tv,
          provider: discoverPopularTvShowsProvider,
          ownedIds: ownedIds,
          settings: settings,
        ),
      );
    }

    if (available.contains(DiscoverSectionId.upcoming) &&
        settings.enabledSections.contains(DiscoverSectionId.upcoming)) {
      sections.add(
        _buildMovieSection(
          context,
          ref,
          title: l.discoverUpcoming,
          icon: Icons.upcoming,
          provider: discoverUpcomingMoviesProvider,
          ownedIds: ownedIds,
          settings: settings,
        ),
      );
    }

    if (available.contains(DiscoverSectionId.anime) &&
        settings.enabledSections.contains(DiscoverSectionId.anime)) {
      sections.add(
        _buildTvShowSection(
          context,
          ref,
          title: l.discoverAnime,
          icon: Icons.animation,
          provider: discoverAnimeProvider,
          ownedIds: ownedIds,
          settings: settings,
        ),
      );
    }

    if (available.contains(DiscoverSectionId.topRatedTvShows) &&
        settings.enabledSections.contains(DiscoverSectionId.topRatedTvShows)) {
      sections.add(
        _buildTvShowSection(
          context,
          ref,
          title: l.discoverTopRatedTvShows,
          icon: Icons.star_border,
          provider: discoverTopRatedTvShowsProvider,
          ownedIds: ownedIds,
          settings: settings,
        ),
      );
    }

    return ListView(
      children: <Widget>[
        // Заголовок Discover
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Text(
            l.discoverTitle,
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xl,
            ),
            child: Center(
              child: Text(
                l.discoverCustomizeHint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...sections.expand(
            (Widget section) => <Widget>[
              section,
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
      ],
    );
  }

  Widget _buildTrendingSection(
    BuildContext context,
    WidgetRef ref,
    S l,
    Set<int> ownedIds,
    DiscoverSettings settings,
  ) {
    // Movies → trending фильмы, TV/Anime → trending сериалы.
    // TMDB trending API не поддерживает фильтр по жанру,
    // поэтому anime и tv используют один провайдер.
    if (sourceId == 'movies') {
      return _buildMovieSection(
        context,
        ref,
        title: l.discoverTrending,
        icon: Icons.local_fire_department,
        provider: discoverTrendingMoviesProvider,
        ownedIds: ownedIds,
        settings: settings,
      );
    }
    return _buildTvShowSection(
      context,
      ref,
      title: l.discoverTrending,
      icon: Icons.local_fire_department,
      provider: discoverTrendingTvShowsProvider,
      ownedIds: ownedIds,
      settings: settings,
    );
  }

  Widget _buildMovieSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required FutureProvider<List<Movie>> provider,
    required Set<int> ownedIds,
    required DiscoverSettings settings,
  }) {
    final AsyncValue<List<Movie>> asyncMovies = ref.watch(provider);

    return asyncMovies.when(
      data: (List<Movie> movies) {
        List<DiscoverItem> items = movies
            .map((Movie m) {
              final bool owned = ownedIds.contains(m.tmdbId);
              if (settings.hideOwned && owned) return null;
              return DiscoverItem(
                title: m.title,
                tmdbId: m.tmdbId,
                posterUrl: m.posterUrl,
                year: m.releaseYear,
                rating: m.formattedRating,
                isOwned: owned,
              );
            })
            .whereType<DiscoverItem>()
            .toList();
        // Не показывать больше 20
        if (items.length > 20) items = items.sublist(0, 20);

        return DiscoverRow(
          title: title,
          icon: icon,
          items: items,
          onTap: (DiscoverItem item) {
            final Movie movie = movies.firstWhere(
              (Movie m) => m.tmdbId == item.tmdbId,
            );
            _showMovieSheet(context, movie);
          },
        );
      },
      loading: () => _buildShimmerRow(context, title),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTvShowSection(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required FutureProvider<List<TvShow>> provider,
    required Set<int> ownedIds,
    required DiscoverSettings settings,
  }) {
    final AsyncValue<List<TvShow>> asyncShows = ref.watch(provider);

    return asyncShows.when(
      data: (List<TvShow> shows) {
        List<DiscoverItem> items = shows
            .map((TvShow s) {
              final bool owned = ownedIds.contains(s.tmdbId);
              if (settings.hideOwned && owned) return null;
              return DiscoverItem(
                title: s.title,
                tmdbId: s.tmdbId,
                posterUrl: s.posterUrl,
                year: s.firstAirYear,
                rating: s.formattedRating,
                isOwned: owned,
                isMovie: false,
              );
            })
            .whereType<DiscoverItem>()
            .toList();
        if (items.length > 20) items = items.sublist(0, 20);

        return DiscoverRow(
          title: title,
          icon: icon,
          items: items,
          onTap: (DiscoverItem item) {
            final TvShow show = shows.firstWhere(
              (TvShow s) => s.tmdbId == item.tmdbId,
            );
            _showTvShowSheet(context, show);
          },
        );
      },
      loading: () => _buildShimmerRow(context, title),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showMovieSheet(BuildContext context, Movie movie) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => MediaDetailsSheet.movie(
        movie,
        onAddToCollection: () => onAddMovie(movie),
      ),
    );
  }

  void _showTvShowSheet(BuildContext context, TvShow tvShow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => MediaDetailsSheet.tvShow(
        tvShow,
        onAddToCollection: () => onAddTvShow(tvShow),
      ),
    );
  }

  Widget _buildShimmerRow(BuildContext context, String title) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 175 : 220;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            title,
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
