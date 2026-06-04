// Episode Tracker section: season/episode watch progress.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/tmdb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../providers/episode_tracker_provider.dart';

/// Episode Tracker section with a progress bar and a season list.
class EpisodeTrackerSection extends ConsumerWidget {
  /// Creates an [EpisodeTrackerSection].
  const EpisodeTrackerSection({
    required this.collectionId,
    required this.externalId,
    required this.tvShow,
    required this.accentColor,
    super.key,
  });

  /// Collection id (null for uncategorized).
  final int? collectionId;

  /// TMDB show id.
  final int externalId;

  /// Show data.
  final TvShow? tvShow;

  /// Accent color (AppColors.brand for tvShow, AppColors.animationAccent
  /// for animation).
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
        SeasonsListWidget(
          tmdbShowId: tmdbShowId,
          collectionId: collectionId,
          accentColor: accentColor,
        ),
      ],
    );
  }
}

/// Season list widget built from ExpansionTiles.
class SeasonsListWidget extends ConsumerStatefulWidget {
  /// Creates a [SeasonsListWidget].
  const SeasonsListWidget({
    required this.tmdbShowId,
    required this.collectionId,
    required this.accentColor,
    super.key,
  });

  /// TMDB show id.
  final int tmdbShowId;

  /// Collection id (null for uncategorized).
  final int? collectionId;

  /// Accent color for the "all watched" indicator.
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
        await db.tvShowDao.getTvSeasonsByShowId(widget.tmdbShowId);

    // Cache miss: fetch from the TMDB API and cache the result
    if (seasons.isEmpty) {
      try {
        final TmdbApi tmdbApi = ref.read(tmdbApiProvider);
        seasons = await tmdbApi.getTvSeasons(widget.tmdbShowId);
        if (seasons.isNotEmpty) {
          await db.tvShowDao.upsertTvSeasons(seasons);
        }
      } on Exception catch (_) {
        // TMDB API unavailable — show empty season list, not critical.
        // User can retry via pull-to-refresh.
      }
    }

    if (mounted) {
      setState(() {
        _seasons = seasons;
        _loading = false;
      });
    }
  }

  /// Force-refreshes the season list and loaded episodes from the API.
  /// Adds new seasons/episodes and refreshes metadata, but leaves
  /// watched statuses untouched.
  Future<void> _refreshSeasons() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final DatabaseService db = ref.read(databaseServiceProvider);
      final TmdbApi tmdbApi = ref.read(tmdbApiProvider);

      final List<TvSeason> seasons =
          await tmdbApi.getTvSeasons(widget.tmdbShowId);
      if (seasons.isNotEmpty) {
        await db.tvShowDao.upsertTvSeasons(seasons);
      }

      // Refresh episodes only for seasons that are already expanded
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
      // Season refresh failed (network/API error) — stop spinner, keep existing data.
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
          if (season.seasonNumber > 0) // skip Specials (season 0)
            SeasonExpansionTile(
              key: ValueKey<int>(season.seasonNumber),
              season: season,
              trackerState: trackerState,
              trackerArg: _trackerArg,
              accentColor: widget.accentColor,
            ),
      ],
    );
  }
}

/// ExpansionTile for a single season and its episodes.
class SeasonExpansionTile extends ConsumerWidget {
  /// Creates a [SeasonExpansionTile].
  const SeasonExpansionTile({
    required this.season,
    required this.trackerState,
    required this.trackerArg,
    required this.accentColor,
    super.key,
  });

  /// Season data.
  final TvSeason season;

  /// Current tracker state.
  final EpisodeTrackerState trackerState;

  /// Argument for the tracker provider.
  final ({int? collectionId, int showId}) trackerArg;

  /// Accent color for the "all watched" indicator.
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
          IconButton(
            icon: Icon(
              allWatched
                  ? Icons.remove_done
                  : Icons.done_all,
              size: 20,
            ),
            tooltip: allWatched ? l.unmarkAll : l.markAllWatched,
            onPressed: () {
              // Load the season first if its episodes aren't loaded yet
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

/// Tile for a single episode with a checkbox.
class EpisodeTile extends ConsumerWidget {
  /// Creates an [EpisodeTile].
  const EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.trackerArg,
    this.watchedAt,
    super.key,
  });

  /// Episode data.
  final TvEpisode episode;

  /// Whether the episode has been watched.
  final bool isWatched;

  /// Watch date (null if not watched).
  final DateTime? watchedAt;

  /// Argument for the tracker provider.
  final ({int? collectionId, int showId}) trackerArg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(settingsNotifierProvider.select((SettingsState s) => s.dateFormat)),
    );
    final String localeName = Localizations.localeOf(context).toLanguageTag();
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
          preset.format(watchedAt!, locale: localeName),
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
