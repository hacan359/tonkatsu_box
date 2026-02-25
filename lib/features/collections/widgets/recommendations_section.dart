// Секция рекомендаций и похожих на странице элемента коллекции.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/models/movie.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../../search/widgets/media_details_sheet.dart';
import '../../settings/providers/settings_provider.dart' show SettingsState, settingsNotifierProvider;

/// Создаёт провайдер рекомендаций к фильму.
FutureProvider<List<Movie>> _createMovieRecProvider(int tmdbId) =>
    FutureProvider<List<Movie>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getMovieRecommendations(tmdbId);
    });

/// Создаёт провайдер рекомендаций к сериалу.
FutureProvider<List<TvShow>> _createTvRecProvider(int tmdbId) =>
    FutureProvider<List<TvShow>>((Ref ref) async {
      final TmdbApi tmdb = ref.watch(tmdbApiProvider);
      return tmdb.getTvRecommendations(tmdbId);
    });

/// Кэш провайдеров рекомендаций фильмов по tmdbId.
final Map<int, FutureProvider<List<Movie>>> _movieRecProviders =
    <int, FutureProvider<List<Movie>>>{};

/// Кэш провайдеров рекомендаций сериалов по tmdbId.
final Map<int, FutureProvider<List<TvShow>>> _tvRecProviders =
    <int, FutureProvider<List<TvShow>>>{};

/// Возвращает кэшированный провайдер рекомендаций фильмов.
FutureProvider<List<Movie>> _getMovieRecProvider(int tmdbId) {
  return _movieRecProviders.putIfAbsent(
    tmdbId,
    () => _createMovieRecProvider(tmdbId),
  );
}

/// Возвращает кэшированный провайдер рекомендаций сериалов.
FutureProvider<List<TvShow>> _getTvRecProvider(int tmdbId) {
  return _tvRecProviders.putIfAbsent(
    tmdbId,
    () => _createTvRecProvider(tmdbId),
  );
}

/// Секция с рекомендациями на странице детального просмотра.
///
/// Показывает горизонтальный список постеров рекомендованных фильмов/сериалов.
/// Не показывается для игр.
class RecommendationsSection extends ConsumerWidget {
  /// Создаёт [RecommendationsSection].
  const RecommendationsSection({
    required this.tmdbId,
    required this.mediaType,
    this.onAddMovie,
    this.onAddTvShow,
    super.key,
  });

  /// TMDB ID элемента.
  final int tmdbId;

  /// Тип медиа.
  final MediaType mediaType;

  /// Callback для добавления фильма в коллекцию.
  final void Function(Movie movie)? onAddMovie;

  /// Callback для добавления сериала в коллекцию.
  final void Function(TvShow tvShow)? onAddTvShow;

  bool get _isTvBased =>
      mediaType == MediaType.tvShow ||
      (mediaType == MediaType.animation);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Проверяем что TMDB API ключ установлен
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
                  rating: m.formattedRating,
                  overview: m.overview,
                  genres: m.genres,
                  icon: Icons.movie_outlined,
                  onAddToCollection: () => _showMovieDetails(context, m),
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
                  rating: s.formattedRating,
                  overview: s.overview,
                  genres: s.genres,
                  icon: Icons.tv_outlined,
                  onAddToCollection: () => _showTvShowDetails(context, s),
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
      builder: (BuildContext ctx) => MediaDetailsSheet(
        title: movie.title,
        icon: Icons.movie_outlined,
        overview: movie.overview,
        year: movie.releaseYear,
        rating: movie.formattedRating,
        genres: movie.genres,
        posterUrl: movie.posterUrl,
        onAddToCollection:
            onAddMovie != null ? () => onAddMovie!(movie) : null,
      ),
    );
  }

  void _showTvShowDetails(BuildContext context, TvShow tvShow) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => MediaDetailsSheet(
        title: tvShow.title,
        icon: Icons.tv_outlined,
        overview: tvShow.overview,
        year: tvShow.firstAirYear,
        rating: tvShow.formattedRating,
        genres: tvShow.genres,
        posterUrl: tvShow.posterUrl,
        onAddToCollection:
            onAddTvShow != null ? () => onAddTvShow!(tvShow) : null,
      ),
    );
  }
}

/// Элемент рекомендации для UI.
class _RecItem {
  const _RecItem({
    required this.title,
    required this.icon,
    required this.onAddToCollection,
    this.posterUrl,
    this.year,
    this.rating,
    this.overview,
    this.genres,
  });

  final String title;
  final String? posterUrl;
  final int? year;
  final String? rating;
  final String? overview;
  final List<String>? genres;
  final IconData icon;
  final VoidCallback onAddToCollection;
}

/// Горизонтальный ряд рекомендаций.
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
    final bool compact = MediaQuery.sizeOf(context).width < 600;
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = compact ? 175 : 220;

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
              itemCount: widget.items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final _RecItem item = widget.items[index];
                return _RecPosterCard(
                  item: item,
                  width: posterWidth,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Карточка постера рекомендации.
class _RecPosterCard extends StatelessWidget {
  const _RecPosterCard({
    required this.item,
    required this.width,
  });

  final _RecItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onAddToCollection,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: _buildPoster(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: AppTypography.posterTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.year != null)
              Text(
                item.year.toString(),
                style: AppTypography.posterSubtitle,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (item.posterUrl == null || item.posterUrl!.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(
            item.icon,
            color: AppColors.textTertiary,
            size: 32,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: item.posterUrl!,
      fit: BoxFit.cover,
      memCacheWidth: 300,
      placeholder: (_, _) => Container(
        color: AppColors.surfaceLight,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        color: AppColors.surfaceLight,
        child: Icon(
          item.icon,
          color: AppColors.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}

/// Шиммер-заглушка при загрузке.
class _RecommendationShimmer extends StatelessWidget {
  const _RecommendationShimmer();

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 600;
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
