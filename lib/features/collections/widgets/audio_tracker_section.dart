import 'dart:async';

import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/musicbrainz_api.dart';
import '../../../core/api/podcast_index_api.dart';
import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/widgets/audio_track_row.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/collections_provider.dart';
import '../providers/item_marks_provider.dart';
import 'item_mark_controls.dart';

/// Listened-track checklist of an album; progress lives in its own
/// `listened_tracks` table, independent from the TV episode tracker.
class AudioTrackerSection extends ConsumerStatefulWidget {
  const AudioTrackerSection({
    required this.itemId,
    required this.collectionId,
    required this.audioItem,
    required this.accentColor,
    super.key,
  });

  final int itemId;
  final int? collectionId;
  final AudioItem? audioItem;
  final Color accentColor;

  @override
  ConsumerState<AudioTrackerSection> createState() =>
      _AudioTrackerSectionState();
}

class _AudioTrackerSectionState extends ConsumerState<AudioTrackerSection> {
  List<AudioTrack>? _tracks;
  Set<(int, int)> _listened = <(int, int)>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final AudioItem? album = widget.audioItem;
    final int? collectionId = widget.collectionId;
    if (album == null || collectionId == null) {
      setState(() => _tracks = const <AudioTrack>[]);
      return;
    }
    final DatabaseService db = ref.read(databaseServiceProvider);

    try {
      final (List<AudioTrack> cached, Map<(int, int), DateTime?> listened) =
          await (
        db.audioDao.getAudioTracks(album.id, source: album.source),
        db.audioDao.getListenedTracks(collectionId, album.source, album.id),
      ).wait;
      List<AudioTrack> tracks =
          cached.isEmpty ? await _fetchAndCacheTracks(album) : cached;
      if (album.isPodcast) {
        if (cached.isNotEmpty) {
          tracks = await _fetchNewEpisodes(album, cached);
        }
        // The natural key orders by episode id; the feed reads newest-first.
        tracks = <AudioTrack>[...tracks]..sort(
            (AudioTrack a, AudioTrack b) =>
                (b.datePublished ?? 0).compareTo(a.datePublished ?? 0),
          );
      }
      if (!album.isPodcast && album.artists.isEmpty) {
        unawaited(_repairMissingArtists(album));
      }

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _listened = listened.keys.toSet();
      });
    } on Object {
      if (!mounted) return;
      // Failed reads render the "no track list" note, never a stuck spinner.
      setState(() => _tracks = const <AudioTrack>[]);
    }
  }

  /// New episodes published after the cached watermark, fetched with `since=`
  /// (cheap) and upserted — the cache only ever grows, the API's 1000-newest
  /// window must not evict what was seen before.
  Future<List<AudioTrack>> _fetchNewEpisodes(
    AudioItem podcast,
    List<AudioTrack> cached,
  ) async {
    try {
      int watermark = 0;
      for (final AudioTrack episode in cached) {
        final int published = episode.datePublished ?? 0;
        if (published > watermark) watermark = published;
      }
      final List<AudioTrack> fresh = await ref
          .read(podcastIndexApiProvider)
          .getEpisodes(podcast.id, since: watermark == 0 ? null : watermark);
      if (fresh.isEmpty) return cached;
      await ref.read(audioDaoProvider).upsertTracks(fresh);
      final Set<int> known =
          cached.map((AudioTrack t) => t.position).toSet();
      return <AudioTrack>[
        ...cached,
        ...fresh.where((AudioTrack t) => !known.contains(t.position)),
      ];
    } on Object {
      // Refresh is best-effort; the cached list is already complete enough.
      return cached;
    }
  }

  /// Rows saved before the lookup carried the artist credit stay artist-less
  /// forever; one lookup here heals them for the next library render.
  Future<void> _repairMissingArtists(AudioItem album) async {
    try {
      final AudioItem? full =
          await ref.read(musicBrainzApiProvider).getReleaseGroup(album.nativeId);
      if (full == null || full.artists.isEmpty) return;
      await ref
          .read(audioDaoProvider)
          .upsertAudioItem(album.withLookupDetails(full));
      final int? collectionId = widget.collectionId;
      if (mounted && collectionId != null) {
        ref.invalidate(collectionItemsNotifierProvider(collectionId));
      }
    } on Object {
      // Cosmetic repair — the card just keeps showing the bare title.
    }
  }

  /// Items imported without a cached track list (an .xcoll from another
  /// device) fetch it once here and keep it for the next open.
  Future<List<AudioTrack>> _fetchAndCacheTracks(AudioItem album) async {
    try {
      if (album.isPodcast) {
        final List<AudioTrack> episodes =
            await ref.read(podcastIndexApiProvider).getEpisodes(album.id);
        if (episodes.isNotEmpty) {
          await ref.read(audioDaoProvider).upsertTracks(episodes);
        }
        return episodes;
      }
      final MusicBrainzApi api = ref.read(musicBrainzApiProvider);
      final String? releaseMbid = album.releaseMbid ??
          (await api.getDefaultRelease(album.nativeId))?.mbid;
      if (releaseMbid == null) return const <AudioTrack>[];
      final List<AudioTrack> tracks =
          await api.getReleaseTracks(releaseMbid, audioId: album.id);
      if (tracks.isNotEmpty) {
        await ref
            .read(audioDaoProvider)
            .replaceAudioTracks(album.id, album.source, tracks);
      }
      return tracks;
    } on Object {
      return const <AudioTrack>[];
    }
  }

  /// Marks a whole span (a year, the full list) listened, or clears it when
  /// every episode in it is already marked. One batched DB write.
  Future<void> _toggleSpan(List<AudioTrack> span) async {
    final AudioItem? album = widget.audioItem;
    final int? collectionId = widget.collectionId;
    if (album == null || collectionId == null || span.isEmpty) return;

    final List<(int, int)> keys = <(int, int)>[
      for (final AudioTrack t in span) (t.discNumber, t.position),
    ];
    final bool allListened = keys.every(_listened.contains);
    try {
      if (allListened) {
        await ref
            .read(audioDaoProvider)
            .markTracksUnlistened(collectionId, album.source, album.id, keys);
      } else {
        final int now = DateTime.now().millisecondsSinceEpoch;
        await ref.read(audioDaoProvider).markTracksListenedAt(
              collectionId,
              album.source,
              album.id,
              <(int, int, int?)>[
                for (final (int disc, int track) in keys)
                  if (!_listened.contains((disc, track))) (disc, track, now),
              ],
            );
      }
    } on Object {
      return;
    }

    if (!mounted) return;
    setState(() {
      _listened = allListened
          ? (<(int, int)>{..._listened}..removeAll(keys))
          : <(int, int)>{..._listened, ...keys};
    });
    unawaited(_updateAutoStatus());
  }

  Future<void> _toggle(AudioTrack track) async {
    final AudioItem? album = widget.audioItem;
    final int? collectionId = widget.collectionId;
    if (album == null || collectionId == null) return;
    final (int, int) key = (track.discNumber, track.position);
    final bool wasListened = _listened.contains(key);

    // DB first, state after success — a failed write must not desync the UI.
    final DataSource source = album.source;
    try {
      if (wasListened) {
        await ref.read(audioDaoProvider).markTrackUnlistened(
            collectionId, source, album.id, track.discNumber, track.position);
      } else {
        await ref.read(audioDaoProvider).markTrackListened(
            collectionId, source, album.id, track.discNumber, track.position);
      }
    } on Object {
      return;
    }

    if (!mounted) return;
    setState(() {
      if (wasListened) {
        _listened = <(int, int)>{..._listened}..remove(key);
      } else {
        _listened = <(int, int)>{..._listened, key};
      }
    });
    unawaited(_updateAutoStatus());
  }

  /// Mirrors the TV tracker: all tracks listened flips the item to completed,
  /// the first mark to in-progress. No-op when totals are unknown.
  Future<void> _updateAutoStatus() async {
    final int? collectionId = widget.collectionId;
    final List<AudioTrack>? tracks = _tracks;
    if (collectionId == null || tracks == null || tracks.isEmpty) return;

    final CollectionItem? item = ref
        .read(collectionItemsNotifierProvider(collectionId))
        .valueOrNull
        ?.where((CollectionItem i) => i.id == widget.itemId)
        .firstOrNull;
    if (item == null) return;

    final ItemStatus? target = computeStatusFromProgress(
      currentStatus: item.status,
      hasAnyProgress: _listened.isNotEmpty,
      isFullyCompleted: _listened.length >= tracks.length,
    );
    if (target != null) {
      await ref
          .read(collectionItemsNotifierProvider(collectionId).notifier)
          .updateStatus(item.id, target, item.mediaType);
    }
  }

  bool get _isPodcast => widget.audioItem?.isPodcast ?? false;

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<AudioTrack>? tracks = _tracks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              _isPodcast ? Icons.podcasts : Icons.queue_music,
              size: 20,
              color: widget.accentColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _isPodcast ? l.podcastSheetEpisodes : l.musicSheetTracks,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (tracks != null && tracks.isNotEmpty) ...<Widget>[
              Text(
                '${_listened.length}/${tracks.length}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              IconButton(
                icon: Icon(
                  _listened.length >= tracks.length
                      ? Icons.remove_done
                      : Icons.done_all,
                  size: 20,
                ),
                tooltip: _listened.length >= tracks.length
                    ? l.unmarkAll
                    : l.markAllListened,
                onPressed: () => _toggleSpan(tracks),
              ),
            ],
          ],
        ),
        if (_isPodcast && tracks != null && tracks.isNotEmpty) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_listened.length / tracks.length).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        if (tracks == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tracks.isEmpty)
          Text(
            l.musicTrackerNoTracks,
            style:
                AppTypography.caption.copyWith(color: AppColors.textTertiary),
          )
        else if (_isPodcast)
          ..._buildEpisodeYearGroups(l, tracks)
        else
          ..._buildTrackRows(l, tracks),
      ],
    );
  }

  List<Widget> _buildTrackRows(S l, List<AudioTrack> tracks) {
    return buildAudioTrackList(
      tracks: tracks,
      discLabel: (int discNumber) => l.musicSheetDisc(discNumber),
      rowBuilder: (AudioTrack track) => _episodeRow(l, track, null),
    );
  }

  /// Small feeds fit on one screen; anything bigger gets collapsible spans.
  static const int _flatEpisodeLimit = 24;

  /// A 600-episode feed as one flat list is unusable — episodes collapse into
  /// per-year spans (per-month when the whole feed fits one calendar year),
  /// newest span open. Undated episodes group under "—" last.
  List<Widget> _buildEpisodeYearGroups(S l, List<AudioTrack> tracks) {
    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.dateFormat),
      ),
    );
    if (tracks.length <= _flatEpisodeLimit) {
      return <Widget>[
        for (final AudioTrack track in tracks) _episodeRow(l, track, preset),
      ];
    }

    final Set<int> years = <int>{
      for (final AudioTrack track in tracks) track.publishedAt?.year ?? 0,
    };
    final bool byMonth = years.length < 2;
    final Map<int, List<AudioTrack>> groups = <int, List<AudioTrack>>{};
    for (final AudioTrack track in tracks) {
      final DateTime? date = track.publishedAt;
      final int key = date == null
          ? 0
          : (byMonth ? date.year * 100 + date.month : date.year);
      groups.putIfAbsent(key, () => <AudioTrack>[]).add(track);
    }

    String label(int key) {
      if (key == 0) return '—';
      if (!byMonth) return '$key';
      return DateFormat.yMMMM(l.localeName)
          .format(DateTime(key ~/ 100, key % 100));
    }

    bool first = true;
    final List<Widget> tiles = <Widget>[];
    for (final MapEntry<int, List<AudioTrack>> entry in groups.entries) {
      final int listened = entry.value
          .where((AudioTrack t) =>
              _listened.contains((t.discNumber, t.position)))
          .length;
      final bool allListened = listened >= entry.value.length;
      tiles.add(ExpansionTile(
        key: PageStorageKey<String>('audio_span_${entry.key}'),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.sm),
        initiallyExpanded: first,
        title: Text(
          label(entry.key),
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '$listened/${entry.value.length}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (listened / entry.value.length).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(widget.accentColor),
              ),
            ),
          ],
        ),
        // The season-tile pattern: the whole-span toggle plus a static
        // chevron, which trailing replaces anyway.
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: Icon(
                allListened ? Icons.remove_done : Icons.done_all,
                size: 20,
              ),
              tooltip: allListened ? l.unmarkAll : l.markAllListened,
              onPressed: () => _toggleSpan(entry.value),
            ),
            const Icon(Icons.expand_more, size: 20),
          ],
        ),
        children: <Widget>[
          for (final AudioTrack track in entry.value)
            _episodeRow(l, track, preset),
        ],
      ));
      first = false;
    }
    return tiles;
  }

  Widget _episodeRow(S l, AudioTrack track, DateFormatPreset? preset) {
    return _TrackTrackerRow(
      key: ValueKey<String>('${track.discNumber}_${track.position}'),
      itemId: widget.itemId,
      track: track,
      listened: _listened.contains((track.discNumber, track.position)),
      accentColor: widget.accentColor,
      onListenedToggle: () => _toggle(track),
      positionLabel: preset == null
          ? null
          : (track.publishedAt != null
              ? preset.format(track.publishedAt!, locale: l.localeName)
              : ''),
      leadingWidth: preset == null ? 24 : kEpisodeDateLeadingWidth,
    );
  }
}

/// One track line in the collection tracker: listened toggle plus the shared
/// like / note controls, bound to the track unit of the item's marks.
class _TrackTrackerRow extends ConsumerStatefulWidget {
  const _TrackTrackerRow({
    required this.itemId,
    required this.track,
    required this.listened,
    required this.accentColor,
    required this.onListenedToggle,
    this.positionLabel,
    this.leadingWidth = 24,
    super.key,
  });

  final int itemId;
  final AudioTrack track;
  final bool listened;
  final Color accentColor;
  final VoidCallback onListenedToggle;
  final String? positionLabel;
  final double leadingWidth;

  @override
  ConsumerState<_TrackTrackerRow> createState() => _TrackTrackerRowState();
}

class _TrackTrackerRowState extends ConsumerState<_TrackTrackerRow> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final AudioTrack track = widget.track;
    final String? note = ref.watch(
      itemMarksProvider(widget.itemId).select((ItemMarksState s) =>
          s.noteFor(kUnitTrack, track.discNumber, track.position)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: AudioTrackRow(
                track: track,
                listened: widget.listened,
                accentColor: widget.accentColor,
                onTap: widget.onListenedToggle,
                positionLabel: widget.positionLabel,
                leadingWidth: widget.leadingWidth,
              ),
            ),
            ItemMarkControls(
              itemId: widget.itemId,
              unitType: kUnitTrack,
              parentNumber: track.discNumber,
              unitNumber: track.position,
              onNotePressed: () =>
                  setState(() => _editingNote = !_editingNote),
            ),
          ],
        ),
        if (_editingNote)
          ItemMarkNoteEditor(
            itemId: widget.itemId,
            unitType: kUnitTrack,
            parentNumber: track.discNumber,
            unitNumber: track.position,
            accentColor: widget.accentColor,
            onDone: () => setState(() => _editingNote = false),
          )
        else if (note != null)
          MarkNoteText(note: note, accentColor: widget.accentColor),
      ],
    );
  }
}
