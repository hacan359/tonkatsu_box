// Episode Tracker section: season/episode watch progress.

import 'package:core/models/data_source.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/tv_episode.dart';
import 'package:core/models/tv_season.dart';
import 'package:core/models/tv_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/episode_source/tv_episode_source.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/widgets/cached_image.dart';
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
    required this.source,
    required this.tvShow,
    required this.accentColor,
    super.key,
  });

  /// Collection id (null for uncategorized).
  final int? collectionId;

  /// Owning `collection_items.id` — anchor for per-episode marks.
  final int itemId;

  /// Show id in the [source] provider's namespace.
  final int externalId;

  final DataSource source;

  /// Show data.
  final TvShow? tvShow;

  /// Accent color (AppColors.brand for tvShow, AppColors.animationAccent
  /// for animation).
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EpisodeTrackerArg trackerArg =
        (collectionId: collectionId, showId: externalId, source: source);

    final EpisodeTrackerState trackerState =
        ref.watch(episodeTrackerNotifierProvider(trackerArg));

    // Sparse cached rows have no totals — fall back to the count the
    // tracker resolved from the seasons cache.
    final int totalEpisodes =
        tvShow?.totalEpisodes ?? trackerState.totalEpisodes ?? 0;
    final int watchedCount = trackerState.totalWatchedCount;

    final S l = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.playlist_add_check, size: 20, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l.episodeProgress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
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
          showId: externalId,
          source: source,
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
    required this.showId,
    required this.source,
    required this.collectionId,
    required this.itemId,
    required this.accentColor,
    super.key,
  });

  /// Show id in the [source] provider's namespace.
  final int showId;

  final DataSource source;

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
    // Episode metadata is skipped on grid-card builds; the detail list is
    // the consumer that needs it (marks titles, expanded seasons).
    Future<void>.microtask(() => ref
        .read(episodeTrackerNotifierProvider(_trackerArg).notifier)
        .ensureCachedEpisodesLoaded());
    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    final DatabaseService db = ref.read(databaseServiceProvider);
    List<TvSeason> seasons =
        await db.tvShowDao.getTvSeasonsByShowId(widget.source, widget.showId);

    if (seasons.isEmpty) {
      try {
        final TvEpisodeSource episodeSource =
            ref.read(tvEpisodeSourceResolverProvider)(widget.source);
        seasons = await episodeSource.getSeasons(widget.showId);
        if (seasons.isNotEmpty) {
          await db.tvShowDao.upsertTvSeasons(seasons);
        }
      } on Exception catch (_) {
        // Source API unavailable — show empty season list, not critical.
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
      final TvEpisodeSource episodeSource =
          ref.read(tvEpisodeSourceResolverProvider)(widget.source);

      final List<TvSeason> seasons =
          await episodeSource.getSeasons(widget.showId);
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

  EpisodeTrackerArg get _trackerArg => (
        collectionId: widget.collectionId,
        showId: widget.showId,
        source: widget.source,
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
  final EpisodeTrackerArg trackerArg;

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

  /// Marks the season's first not-yet-watched episode, loading the season
  /// from the source first if its episodes aren't in memory.
  Future<void> _markNextWatched() async {
    final int seasonNum = widget.season.seasonNumber;
    final EpisodeTrackerNotifier notifier =
        ref.read(episodeTrackerNotifierProvider(widget.trackerArg).notifier);

    EpisodeTrackerState state =
        ref.read(episodeTrackerNotifierProvider(widget.trackerArg));
    if (state.episodesBySeason[seasonNum]?.isEmpty ?? true) {
      await notifier.loadSeason(seasonNum);
      if (!mounted) return;
      state = ref.read(episodeTrackerNotifierProvider(widget.trackerArg));
    }

    final List<TvEpisode> episodes =
        state.episodesBySeason[seasonNum] ?? const <TvEpisode>[];
    if (episodes.isEmpty) return;

    final List<TvEpisode> ordered = <TvEpisode>[...episodes]
      ..sort((TvEpisode a, TvEpisode b) =>
          a.episodeNumber.compareTo(b.episodeNumber));
    for (final TvEpisode ep in ordered) {
      if (!state.isEpisodeWatched(seasonNum, ep.episodeNumber)) {
        await notifier.toggleEpisode(seasonNum, ep.episodeNumber);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TvSeason season = widget.season;
    final EpisodeTrackerState trackerState = widget.trackerState;
    final EpisodeTrackerArg trackerArg = widget.trackerArg;
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
    final String? airDate = season.airDate;
    final int? airYear = airDate != null && airDate.length >= 4
        ? int.tryParse(airDate.substring(0, 4))
        : null;
    final String subtitle = <String>[
      episodeCount > 0
          ? l.seasonEpisodesProgress(watchedCount, episodeCount)
          : l.episodesWatched(watchedCount),
      if (airYear != null) '$airYear',
    ].join(' • ');
    final String? note = ref.watch(
      itemMarksProvider(itemId).select(
        (ItemMarksState s) => s.noteFor(kUnitSeason, seasonNum, 0),
      ),
    );

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
      leading: _SeasonLeading(
        season: season,
        source: trackerArg.source,
        allWatched: allWatched,
        accentColor: accentColor,
      ),
      title: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              seasonTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (episodeCount > 0) ...<Widget>[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (watchedCount / episodeCount).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
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
          if (!allWatched && episodeCount > 0)
            IconButton(
              icon: const Icon(Icons.playlist_add_check, size: 20),
              tooltip: l.markNextWatched,
              onPressed: _markNextWatched,
            ),
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
                seasonPosterUrl: season.posterUrl,
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
    this.seasonPosterUrl,
    super.key,
  });

  /// Episode data.
  final TvEpisode episode;

  /// Stands in when the episode has no still of its own.
  final String? seasonPosterUrl;

  /// Whether the episode has been watched.
  final bool isWatched;

  /// Watch date (null if not watched).
  final DateTime? watchedAt;

  /// Argument for the tracker provider.
  final EpisodeTrackerArg trackerArg;

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

    final String? overview = episode.overview;

    // Kitsu ships stills for some episodes only; the season poster keeps the
    // rows aligned instead of leaving a ragged gap where a still is missing.
    final bool hasOwnStill = episode.stillUrl != null;
    final String? stillUrl = episode.stillUrl ?? widget.seasonPosterUrl;

    // A 96px still eats a third of a phone row and long titles/synopses then
    // wrap into tall uneven blocks — give the text the width back on mobile.
    final double stillWidth = kIsMobile ? 72 : 96;
    final double stillHeight = kIsMobile ? 40 : 54;

    void toggle() {
      ref
          .read(episodeTrackerNotifierProvider(widget.trackerArg).notifier)
          .toggleEpisode(episode.seasonNumber, episode.episodeNumber);
    }

    final Widget tile = InkWell(
      onTap: toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (stillUrl != null) ...<Widget>[
              // Watched episodes get a dimmed still with a check badge,
              // matching the struck-through title; the row tap toggles.
              Stack(
                children: <Widget>[
                  Opacity(
                    opacity: isWatched ? 0.55 : 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: CachedImage(
                        imageType: ImageType.tvEpisodeStill,
                        // Keyed by what is actually shown: a season poster
                        // standing in for a still must not be cached under the
                        // episode's own id, or it would stick once the real
                        // still appears.
                        imageId: hasOwnStill
                            ? '${widget.trackerArg.source.name}_'
                                '${episode.tmdbShowId}_'
                                's${episode.seasonNumber}'
                                'e${episode.episodeNumber}'
                            : '${widget.trackerArg.source.name}_'
                                '${episode.tmdbShowId}_'
                                's${episode.seasonNumber}_poster',
                        remoteUrl: stillUrl,
                        width: stillWidth,
                        height: stillHeight,
                        fit: BoxFit.cover,
                        memCacheWidth: 192,
                        placeholder:
                            const ColoredBox(color: AppColors.surfaceLight),
                        errorWidget:
                            const ColoredBox(color: AppColors.surfaceLight),
                      ),
                    ),
                  ),
                  if (isWatched)
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: _WatchedBadge(accentColor: widget.accentColor),
                    ),
                ],
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              decoration: isWatched
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isWatched
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
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
                  if (subtitleParts.isNotEmpty)
                    Text(
                      subtitleParts.join(' \u2022 '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (overview != null && overview.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    _ExpandableOverview(text: overview),
                  ],
                  if (note != null && !_editingNote)
                    MarkNoteText(note: note, accentColor: widget.accentColor),
                ],
              ),
            ),
          ],
        ),
      ),
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

/// Season poster thumbnail with an "all watched" badge; falls back to the
/// plain check indicator when the source has no poster for the season.
class _SeasonLeading extends StatelessWidget {
  const _SeasonLeading({
    required this.season,
    required this.source,
    required this.allWatched,
    required this.accentColor,
  });

  final TvSeason season;
  final DataSource source;
  final bool allWatched;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final String? posterUrl = season.posterUrl;
    if (posterUrl == null) {
      return Icon(
        allWatched ? Icons.check_circle : Icons.circle_outlined,
        color: allWatched ? accentColor : AppColors.surfaceBorder,
        size: 20,
      );
    }
    return SizedBox(
      width: 40,
      height: 60,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: CachedImage(
              imageType: ImageType.tvSeasonPoster,
              imageId: '${source.name}_${season.tmdbShowId}_'
                  's${season.seasonNumber}',
              remoteUrl: posterUrl,
              fit: BoxFit.cover,
              memCacheWidth: 120,
              placeholder: const ColoredBox(color: AppColors.surfaceLight),
              errorWidget: const ColoredBox(color: AppColors.surfaceLight),
            ),
          ),
          if (allWatched)
            Positioned(
              right: 2,
              bottom: 2,
              child: _WatchedBadge(accentColor: accentColor, size: 14),
            ),
        ],
      ),
    );
  }
}

/// Check-circle badge shown over a poster/still corner for watched items.
class _WatchedBadge extends StatelessWidget {
  const _WatchedBadge({required this.accentColor, this.size = 15});

  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(200),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle, color: accentColor, size: size),
    );
  }
}

/// Episode overview clamped to two lines; tap toggles the full text.
/// `canRequestFocus: false` keeps it out of D-pad traversal — the row's
/// own InkWell stays the single gamepad stop per episode.
class _ExpandableOverview extends StatefulWidget {
  const _ExpandableOverview({required this.text});

  final String text;

  @override
  State<_ExpandableOverview> createState() => _ExpandableOverviewState();
}

class _ExpandableOverviewState extends State<_ExpandableOverview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      canRequestFocus: false,
      child: Text(
        widget.text,
        maxLines: _expanded ? null : 2,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: AppColors.textTertiary,
          height: 1.35,
        ),
      ),
    );
  }
}
