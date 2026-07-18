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
import '../../../shared/models/item_mark.dart';
import '../../../shared/models/tv_episode.dart';
import '../../../shared/models/tv_season.dart';
import '../../../shared/models/tv_show.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../providers/episode_tracker_provider.dart';
import '../providers/item_marks_provider.dart';
import 'item_mark_controls.dart';

/// Filter for the episode marks bar.
enum _EpisodeMarkFilter { all, liked, commented }

/// Episode Tracker section with a progress bar and a season list.
class EpisodeTrackerSection extends ConsumerWidget {
  /// Creates an [EpisodeTrackerSection].
  const EpisodeTrackerSection({
    required this.collectionId,
    required this.itemId,
    required this.externalId,
    required this.tvShow,
    required this.accentColor,
    super.key,
  });

  /// Collection id (null for uncategorized).
  final int? collectionId;

  /// Owning `collection_items.id` — anchor for per-episode marks.
  final int itemId;

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
          itemId: itemId,
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
    required this.itemId,
    required this.accentColor,
    super.key,
  });

  /// TMDB show id.
  final int tmdbShowId;

  /// Collection id (null for uncategorized).
  final int? collectionId;

  /// Owning `collection_items.id` — anchor for per-episode marks.
  final int itemId;

  /// Accent color for the "all watched" indicator.
  final Color accentColor;

  @override
  ConsumerState<SeasonsListWidget> createState() => _SeasonsListWidgetState();
}

class _SeasonsListWidgetState extends ConsumerState<SeasonsListWidget> {
  List<TvSeason> _seasons = <TvSeason>[];
  bool _loading = true;
  bool _refreshing = false;
  _EpisodeMarkFilter _filter = _EpisodeMarkFilter.all;

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
    final ItemMarksState marks =
        ref.watch(itemMarksProvider(widget.itemId));

    // Specials (season 0) go last; they are excluded from overall progress.
    final List<TvSeason> orderedSeasons = <TvSeason>[
      for (final TvSeason s in _seasons)
        if (s.seasonNumber > 0) s,
      for (final TvSeason s in _seasons)
        if (s.seasonNumber == 0) s,
    ];

    return Column(
      children: <Widget>[
        _buildMarksBar(marks),
        if (_filter != _EpisodeMarkFilter.all)
          _buildFilteredList(marks, trackerState)
        else ...<Widget>[
          for (final TvSeason season in orderedSeasons)
            SeasonExpansionTile(
              key: ValueKey<int>(season.seasonNumber),
              season: season,
              trackerState: trackerState,
              trackerArg: _trackerArg,
              itemId: widget.itemId,
              accentColor: widget.accentColor,
            ),
        ],
      ],
    );
  }

  /// Summary (`❤ N · 💬 M`, episode marks only) plus filter chips.
  Widget _buildMarksBar(ItemMarksState marks) {
    final int liked = marks.likedCountOfType(kUnitEpisode);
    final int commented = marks.commentedCountOfType(kUnitEpisode);
    final S l = S.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          const Icon(Icons.favorite, size: 13, color: AppColors.favorite),
          const SizedBox(width: 2),
          Text(
            '$liked',
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.sticky_note_2,
              size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 2),
          Text(
            '$commented',
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          _filterChip(Icons.list, l.all,
              _EpisodeMarkFilter.all),
          const SizedBox(width: 4),
          _filterChip(Icons.favorite, l.itemMarkFilterLiked,
              _EpisodeMarkFilter.liked,
              color: AppColors.favorite),
          const SizedBox(width: 4),
          _filterChip(Icons.sticky_note_2, l.itemMarkFilterCommented,
              _EpisodeMarkFilter.commented),
          const SizedBox(width: AppSpacing.sm),
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.all(4),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: l.refreshFromTmdb,
              onPressed: _refreshSeasons,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _filterChip(
    IconData icon,
    String tooltip,
    _EpisodeMarkFilter filter, {
    Color? color,
  }) {
    final bool selected = _filter == filter;
    final Color chipColor = color ?? AppColors.textTertiary;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _filter = filter),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: selected ? chipColor.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected
                  ? chipColor.withAlpha(80)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: selected ? chipColor : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  /// Flat list of episode marks matching the active filter, across all
  /// seasons. Draws from the marks provider directly, so it works even when a
  /// season's episode metadata hasn't been loaded (falls back to `S1·E3`).
  Widget _buildFilteredList(
    ItemMarksState marks,
    EpisodeTrackerState trackerState,
  ) {
    final S l = S.of(context);
    final List<ItemMark> episodeMarks = marks.all
        .where((ItemMark m) => m.unitType == kUnitEpisode && _matchesFilter(m))
        .toList()
      ..sort((ItemMark a, ItemMark b) {
        final int byParent = a.parentNumber.compareTo(b.parentNumber);
        if (byParent != 0) return byParent;
        return a.unitNumber.compareTo(b.unitNumber);
      });

    if (episodeMarks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          l.itemMarkEmpty,
          style:
              AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: <Widget>[
        for (final ItemMark m in episodeMarks)
          _FilteredEpisodeRow(
            key: ValueKey<String>('${m.parentNumber}:${m.unitNumber}'),
            mark: m,
            title: _episodeTitle(m, trackerState, l),
            itemId: widget.itemId,
            accentColor: widget.accentColor,
          ),
      ],
    );
  }

  bool _matchesFilter(ItemMark m) => _filter == _EpisodeMarkFilter.liked
      ? m.isFavorite
      : m.note != null;

  String _episodeTitle(
    ItemMark m,
    EpisodeTrackerState trackerState,
    S l,
  ) {
    final List<TvEpisode>? episodes =
        trackerState.episodesBySeason[m.parentNumber];
    if (episodes != null) {
      for (final TvEpisode ep in episodes) {
        if (ep.episodeNumber == m.unitNumber && ep.name.isNotEmpty) {
          return ep.name;
        }
      }
    }
    return l.itemMarkEpisodeShort(m.parentNumber, m.unitNumber);
  }
}

/// One row in the flattened liked/commented episode list.
class _FilteredEpisodeRow extends StatefulWidget {
  const _FilteredEpisodeRow({
    required this.mark,
    required this.title,
    required this.itemId,
    required this.accentColor,
    super.key,
  });

  final ItemMark mark;
  final String title;
  final int itemId;
  final Color accentColor;

  @override
  State<_FilteredEpisodeRow> createState() => _FilteredEpisodeRowState();
}

class _FilteredEpisodeRowState extends State<_FilteredEpisodeRow> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final ItemMark mark = widget.mark;
    final String title = widget.title;
    final int itemId = widget.itemId;
    final S l = S.of(context);
    final String? note = mark.note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: l.itemMarkEpisodeShort(
                          mark.parentNumber,
                          mark.unitNumber,
                        ),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.textTertiary),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: title, style: AppTypography.bodySmall),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ItemMarkControls(
                itemId: itemId,
                unitType: kUnitEpisode,
                parentNumber: mark.parentNumber,
                unitNumber: mark.unitNumber,
                onNotePressed: () =>
                    setState(() => _editingNote = !_editingNote),
              ),
            ],
          ),
          if (_editingNote)
            ItemMarkNoteEditor(
              itemId: itemId,
              unitType: kUnitEpisode,
              parentNumber: mark.parentNumber,
              unitNumber: mark.unitNumber,
              accentColor: widget.accentColor,
              onDone: () => setState(() => _editingNote = false),
            )
          else if (note != null)
            MarkNoteText(note: note, accentColor: widget.accentColor),
        ],
      ),
    );
  }
}

/// ExpansionTile for a single season and its episodes.
class SeasonExpansionTile extends ConsumerStatefulWidget {
  /// Creates a [SeasonExpansionTile].
  const SeasonExpansionTile({
    required this.season,
    required this.trackerState,
    required this.trackerArg,
    required this.itemId,
    required this.accentColor,
    super.key,
  });

  /// Season data.
  final TvSeason season;

  /// Current tracker state.
  final EpisodeTrackerState trackerState;

  /// Argument for the tracker provider.
  final ({int? collectionId, int showId}) trackerArg;

  /// Owning `collection_items.id` — anchor for per-episode/season marks.
  final int itemId;

  /// Accent color for the "all watched" indicator.
  final Color accentColor;

  @override
  ConsumerState<SeasonExpansionTile> createState() =>
      _SeasonExpansionTileState();
}

class _SeasonExpansionTileState extends ConsumerState<SeasonExpansionTile> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final TvSeason season = widget.season;
    final EpisodeTrackerState trackerState = widget.trackerState;
    final ({int? collectionId, int showId}) trackerArg = widget.trackerArg;
    final int itemId = widget.itemId;
    final Color accentColor = widget.accentColor;
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
    final String? note = ref.watch(
      itemMarksProvider(itemId).select(
        (ItemMarksState s) => s.noteFor(kUnitSeason, seasonNum, 0),
      ),
    );

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      leading: Icon(
        allWatched ? Icons.check_circle : Icons.circle_outlined,
        color: allWatched ? accentColor : AppColors.surfaceBorder,
        size: 20,
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              seasonTitle,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ItemMarkControls(
            itemId: itemId,
            unitType: kUnitSeason,
            parentNumber: seasonNum,
            unitNumber: 0,
            showLike: false,
            onNotePressed: () =>
                setState(() => _editingNote = !_editingNote),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_editingNote)
            ItemMarkNoteEditor(
              itemId: itemId,
              unitType: kUnitSeason,
              parentNumber: seasonNum,
              unitNumber: 0,
              accentColor: accentColor,
              onDone: () => setState(() => _editingNote = false),
            )
          else if (note != null)
            MarkNoteText(note: note, accentColor: accentColor),
        ],
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
                  if (!mounted) return;
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
                itemId: itemId,
                accentColor: accentColor,
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
class EpisodeTile extends ConsumerStatefulWidget {
  /// Creates an [EpisodeTile].
  const EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.trackerArg,
    required this.itemId,
    required this.accentColor,
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

  /// Owning `collection_items.id` — anchor for per-episode marks.
  final int itemId;

  /// Accent color of the section, tints the note block.
  final Color accentColor;

  @override
  ConsumerState<EpisodeTile> createState() => _EpisodeTileState();
}

class _EpisodeTileState extends ConsumerState<EpisodeTile> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final TvEpisode episode = widget.episode;
    final bool isWatched = widget.isWatched;
    final DateTime? watchedAt = widget.watchedAt;
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
          preset.format(watchedAt, locale: localeName),
        ),
      );
    }
    final String? note = ref.watch(
      itemMarksProvider(widget.itemId).select(
        (ItemMarksState s) => s.noteFor(
          kUnitEpisode,
          episode.seasonNumber,
          episode.episodeNumber,
        ),
      ),
    );

    final Widget tile = CheckboxListTile(
      value: isWatched,
      onChanged: (_) {
        ref
            .read(episodeTrackerNotifierProvider(widget.trackerArg).notifier)
            .toggleEpisode(
              episode.seasonNumber,
              episode.episodeNumber,
            );
      },
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                decoration: isWatched ? TextDecoration.lineThrough : null,
                color: isWatched
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          ItemMarkControls(
            itemId: widget.itemId,
            unitType: kUnitEpisode,
            parentNumber: episode.seasonNumber,
            unitNumber: episode.episodeNumber,
            onNotePressed: () =>
                setState(() => _editingNote = !_editingNote),
          ),
        ],
      ),
      subtitle: (subtitleParts.isNotEmpty || (note != null && !_editingNote))
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' \u2022 '),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (note != null && !_editingNote)
                  MarkNoteText(note: note, accentColor: widget.accentColor),
              ],
            )
          : null,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      visualDensity: VisualDensity.compact,
    );

    if (!_editingNote) return tile;

    return Column(
      children: <Widget>[
        tile,
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xl + AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.xs,
          ),
          child: ItemMarkNoteEditor(
            itemId: widget.itemId,
            unitType: kUnitEpisode,
            parentNumber: episode.seasonNumber,
            unitNumber: episode.episodeNumber,
            accentColor: widget.accentColor,
            onDone: () => setState(() => _editingNote = false),
          ),
        ),
      ],
    );
  }
}
