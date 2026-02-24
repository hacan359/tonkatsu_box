// Секция Episode Tracker — прогресс просмотра сезонов/эпизодов.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../providers/episode_tracker_provider.dart';

/// Секция Episode Tracker с прогресс-баром и списком сезонов.
class EpisodeTrackerSection extends ConsumerWidget {
  /// Создаёт [EpisodeTrackerSection].
  const EpisodeTrackerSection({
    required this.collectionId,
    required this.externalId,
    required this.tvShow,
    required this.accentColor,
    super.key,
  });

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// TMDB ID шоу.
  final int externalId;

  /// Данные сериала.
  final TvShow? tvShow;

  /// Акцентный цвет (AppColors.brand для tvShow, AppColors.animationAccent
  /// для анимации).
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int tmdbShowId = externalId;
    final ({int? collectionId, int showId}) trackerArg =
        (collectionId: collectionId, showId: tmdbShowId);

    final EpisodeTrackerState trackerState =
        ref.watch(episodeTrackerNotifierProvider(trackerArg));

    final int totalEpisodes = tvShow?.totalEpisodes ?? 0;
    final int watchedCount = trackerState.totalWatchedCount;

    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Заголовок и общий прогресс
        Row(
          children: <Widget>[
            Icon(Icons.playlist_add_check, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.episodeProgress,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              totalEpisodes > 0
                  ? l.episodesWatchedOf(watchedCount, totalEpisodes)
                  : l.episodesWatched(watchedCount),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (totalEpisodes > 0) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: watchedCount / totalEpisodes,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Список сезонов
        SeasonsListWidget(
          tmdbShowId: tmdbShowId,
          collectionId: collectionId,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

/// Виджет списка сезонов с ExpansionTile.
class SeasonsListWidget extends ConsumerStatefulWidget {
  /// Создаёт [SeasonsListWidget].
  const SeasonsListWidget({
    required this.tmdbShowId,
    required this.collectionId,
    required this.accentColor,
    super.key,
  });

  /// TMDB ID шоу.
  final int tmdbShowId;

  /// ID коллекции (null для uncategorized).
  final int? collectionId;

  /// Акцентный цвет для индикатора «все просмотрены».
  final Color accentColor;

  @override
  ConsumerState<SeasonsListWidget> createState() => _SeasonsListWidgetState();
}

class _SeasonsListWidgetState extends ConsumerState<SeasonsListWidget> {
  List<TvSeason> _seasons = <TvSeason>[];
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    List<TvSeason> seasons =
        await db.getTvSeasonsByShowId(widget.tmdbShowId);

    // Если в кэше пусто — загружаем из TMDB API и кэшируем
    if (seasons.isEmpty) {
      try {
        final TmdbApi tmdbApi = ref.read(tmdbApiProvider);
        seasons = await tmdbApi.getTvSeasons(widget.tmdbShowId);
        if (seasons.isNotEmpty) {
          await db.upsertTvSeasons(seasons);
        }
      } on Exception catch (_) {
        // Если API недоступен — покажем пустой список
      }
    }

    if (mounted) {
      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    }
  }

  /// Принудительно обновляет список сезонов и загруженные эпизоды из API.
  /// Добавляет новые сезоны/эпизоды, обновляет метаданные,
  /// не трогает watched-статусы.
  Future<void> _refreshSeasons() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final DatabaseService db = ref.read(databaseServiceProvider);
      final TmdbApi tmdbApi = ref.read(tmdbApiProvider);

      // Обновляем список сезонов
      final List<TvSeason> seasons =
          await tmdbApi.getTvSeasons(widget.tmdbShowId);
      if (seasons.isNotEmpty) {
        await db.upsertTvSeasons(seasons);
      }

      // Обновляем эпизоды для каждого уже раскрытого сезона
      final EpisodeTrackerNotifier tracker = ref.read(
        episodeTrackerNotifierProvider(_trackerArg).notifier,
      );
      final EpisodeTrackerState trackerState = ref.read(
        episodeTrackerNotifierProvider(_trackerArg),
      );
      for (final int seasonNum in trackerState.episodesBySeason.keys) {
        await tracker.refreshSeason(seasonNum);
      }

      if (mounted) {
        setState(() {
          _seasons = seasons;
          _refreshing = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  ({int? collectionId, int showId}) get _trackerArg => (
        collectionId: widget.collectionId,
        showId: widget.tmdbShowId,
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_seasons.isEmpty) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              S.of(context).noSeasonData,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: S.of(context).refreshFromTmdb,
            onPressed: _refreshing ? null : _refreshSeasons,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
          ),
        ],
      );
    }

    final EpisodeTrackerState trackerState =
        ref.watch(episodeTrackerNotifierProvider(_trackerArg));

    return Column(
      children: <Widget>[
        // Кнопка обновления данных из TMDB
        Align(
          alignment: Alignment.centerRight,
          child: _refreshing
              ? const Padding(
                  padding: EdgeInsets.all(4),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: S.of(context).refreshFromTmdb,
                  onPressed: _refreshSeasons,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  visualDensity: VisualDensity.compact,
                ),
        ),
        for (final TvSeason season in _seasons)
          if (season.seasonNumber > 0) // Пропускаем Specials (сезон 0)
            SeasonExpansionTile(
              season: season,
              trackerState: trackerState,
              trackerArg: _trackerArg,
              accentColor: widget.accentColor,
            ),
      ],
    );
  }
}

/// ExpansionTile для одного сезона с эпизодами.
class SeasonExpansionTile extends ConsumerWidget {
  /// Создаёт [SeasonExpansionTile].
  const SeasonExpansionTile({
    required this.season,
    required this.trackerState,
    required this.trackerArg,
    required this.accentColor,
    super.key,
  });

  /// Данные сезона.
  final TvSeason season;

  /// Текущее состояние трекера.
  final EpisodeTrackerState trackerState;

  /// Аргумент для провайдера трекера.
  final ({int? collectionId, int showId}) trackerArg;

  /// Акцентный цвет для индикатора «все просмотрены».
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final int seasonNum = season.seasonNumber;
    final int episodeCount = season.episodeCount ?? 0;
    final int watchedCount = trackerState.watchedCountForSeason(seasonNum);
    final bool allWatched = episodeCount > 0 && watchedCount >= episodeCount;
    final bool isLoading = trackerState.loadingSeasons[seasonNum] == true;
    final List<TvEpisode>? episodes =
        trackerState.episodesBySeason[seasonNum];

    final String seasonTitle =
        season.name ?? l.seasonName(seasonNum);
    final String subtitle = episodeCount > 0
        ? l.seasonEpisodesProgress(watchedCount, episodeCount)
        : l.episodesWatched(watchedCount);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      leading: Icon(
        allWatched ? Icons.check_circle : Icons.circle_outlined,
        color: allWatched ? accentColor : AppColors.surfaceBorder,
        size: 20,
      ),
      title: Text(
        seasonTitle,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Кнопка Mark all / Unmark all
          IconButton(
            icon: Icon(
              allWatched
                  ? Icons.remove_done
                  : Icons.done_all,
              size: 18,
            ),
            tooltip: allWatched ? l.unmarkAll : l.markAllWatched,
            onPressed: () {
              // Если эпизоды ещё не загружены, сначала загрузим
              if (episodes == null || episodes.isEmpty) {
                ref
                    .read(episodeTrackerNotifierProvider(trackerArg).notifier)
                    .loadSeason(seasonNum)
                    .then((_) {
                  ref
                      .read(
                          episodeTrackerNotifierProvider(trackerArg).notifier)
                      .toggleSeason(seasonNum);
                });
              } else {
                ref
                    .read(episodeTrackerNotifierProvider(trackerArg).notifier)
                    .toggleSeason(seasonNum);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
          ),
          const Icon(Icons.expand_more, size: 20),
        ],
      ),
      onExpansionChanged: (bool expanded) {
        if (expanded) {
          ref
              .read(episodeTrackerNotifierProvider(trackerArg).notifier)
              .loadSeason(seasonNum);
        }
      },
      children: <Widget>[
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (episodes != null && episodes.isNotEmpty)
          ...episodes.map((TvEpisode episode) => EpisodeTile(
                episode: episode,
                isWatched: trackerState.isEpisodeWatched(
                  seasonNum,
                  episode.episodeNumber,
                ),
                watchedAt: trackerState.getWatchedAt(
                  seasonNum,
                  episode.episodeNumber,
                ),
                trackerArg: trackerArg,
              ))
        else if (episodes != null && episodes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              l.noEpisodesFound,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Тайл одного эпизода с чекбоксом.
class EpisodeTile extends ConsumerWidget {
  /// Создаёт [EpisodeTile].
  const EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.trackerArg,
    this.watchedAt,
    super.key,
  });

  /// Данные эпизода.
  final TvEpisode episode;

  /// Просмотрен ли эпизод.
  final bool isWatched;

  /// Дата просмотра (null, если не просмотрен).
  final DateTime? watchedAt;

  /// Аргумент для провайдера трекера.
  final ({int? collectionId, int showId}) trackerArg;

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String title =
        'E${episode.episodeNumber}: ${episode.name}';
    final List<String> subtitleParts = <String>[];
    if (episode.airDate != null) {
      subtitleParts.add(episode.airDate!);
    }
    if (episode.runtime != null) {
      subtitleParts.add(S.of(context).runtimeMinutes(episode.runtime!));
    }
    if (isWatched && watchedAt != null) {
      subtitleParts.add(
        S.of(context).episodeWatchedDate(
          '${_months[watchedAt!.month - 1]} ${watchedAt!.day}',
        ),
      );
    }

    return CheckboxListTile(
      value: isWatched,
      onChanged: (_) {
        ref
            .read(episodeTrackerNotifierProvider(trackerArg).notifier)
            .toggleEpisode(
              episode.seasonNumber,
              episode.episodeNumber,
            );
      },
      title: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          decoration: isWatched ? TextDecoration.lineThrough : null,
          color: isWatched
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitleParts.isNotEmpty
          ? Text(
              subtitleParts.join(' \u2022 '),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      visualDensity: VisualDensity.compact,
    );
  }
}
