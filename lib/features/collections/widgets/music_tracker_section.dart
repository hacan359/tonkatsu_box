import 'dart:async';

import 'package:core/models/album.dart';
import 'package:core/models/album_track.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/item_mark.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/item_status_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/musicbrainz_api.dart';
import '../../../core/database/database_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/album_track_row.dart';
import '../providers/collections_provider.dart';
import '../providers/item_marks_provider.dart';
import 'item_mark_controls.dart';

/// Listened-track checklist of an album; progress lives in its own
/// `listened_tracks` table, independent from the TV episode tracker.
class MusicTrackerSection extends ConsumerStatefulWidget {
  const MusicTrackerSection({
    required this.itemId,
    required this.collectionId,
    required this.album,
    required this.accentColor,
    super.key,
  });

  final int itemId;
  final int? collectionId;
  final Album? album;
  final Color accentColor;

  @override
  ConsumerState<MusicTrackerSection> createState() =>
      _MusicTrackerSectionState();
}

class _MusicTrackerSectionState extends ConsumerState<MusicTrackerSection> {
  List<AlbumTrack>? _tracks;
  Set<(int, int)> _listened = <(int, int)>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Album? album = widget.album;
    final int? collectionId = widget.collectionId;
    if (album == null || collectionId == null) {
      setState(() => _tracks = const <AlbumTrack>[]);
      return;
    }
    final DatabaseService db = ref.read(databaseServiceProvider);

    try {
      final (List<AlbumTrack> cached, Map<(int, int), DateTime?> listened) =
          await (
        db.albumDao.getAlbumTracks(album.id, source: album.source),
        db.albumDao.getListenedTracks(collectionId, album.source, album.id),
      ).wait;
      final List<AlbumTrack> tracks =
          cached.isEmpty ? await _fetchAndCacheTracks(album) : cached;
      if (album.artists.isEmpty) unawaited(_repairMissingArtists(album));

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _listened = listened.keys.toSet();
      });
    } on Object {
      if (!mounted) return;
      // Failed reads render the "no track list" note, never a stuck spinner.
      setState(() => _tracks = const <AlbumTrack>[]);
    }
  }

  /// Rows saved before the lookup carried the artist credit stay artist-less
  /// forever; one lookup here heals them for the next library render.
  Future<void> _repairMissingArtists(Album album) async {
    try {
      final Album? full =
          await ref.read(musicBrainzApiProvider).getReleaseGroup(album.mbid);
      if (full == null || full.artists.isEmpty) return;
      await ref
          .read(albumDaoProvider)
          .upsertAlbum(album.withLookupDetails(full));
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
  Future<List<AlbumTrack>> _fetchAndCacheTracks(Album album) async {
    try {
      final MusicBrainzApi api = ref.read(musicBrainzApiProvider);
      final String? releaseMbid = album.releaseMbid ??
          (await api.getDefaultRelease(album.mbid))?.mbid;
      if (releaseMbid == null) return const <AlbumTrack>[];
      final List<AlbumTrack> tracks =
          await api.getReleaseTracks(releaseMbid, albumId: album.id);
      if (tracks.isNotEmpty) {
        await ref
            .read(albumDaoProvider)
            .replaceAlbumTracks(album.id, album.source, tracks);
      }
      return tracks;
    } on Object {
      return const <AlbumTrack>[];
    }
  }

  Future<void> _toggle(AlbumTrack track) async {
    final Album? album = widget.album;
    final int? collectionId = widget.collectionId;
    if (album == null || collectionId == null) return;
    final (int, int) key = (track.discNumber, track.position);
    final bool wasListened = _listened.contains(key);

    // DB first, state after success — a failed write must not desync the UI.
    final DataSource source = album.source;
    try {
      if (wasListened) {
        await ref.read(albumDaoProvider).markTrackUnlistened(
            collectionId, source, album.id, track.discNumber, track.position);
      } else {
        await ref.read(albumDaoProvider).markTrackListened(
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
    final List<AlbumTrack>? tracks = _tracks;
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

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final List<AlbumTrack>? tracks = _tracks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.queue_music, size: 20, color: widget.accentColor),
            const SizedBox(width: AppSpacing.sm),
            Text(
              l.musicSheetTracks,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (tracks != null && tracks.isNotEmpty)
              Text(
                '${_listened.length}/${tracks.length}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
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
        else
          ..._buildTrackRows(l, tracks),
      ],
    );
  }

  List<Widget> _buildTrackRows(S l, List<AlbumTrack> tracks) {
    return buildAlbumTrackList(
      tracks: tracks,
      discLabel: (int discNumber) => l.musicSheetDisc(discNumber),
      rowBuilder: (AlbumTrack track) => _TrackTrackerRow(
        key: ValueKey<String>('${track.discNumber}_${track.position}'),
        itemId: widget.itemId,
        track: track,
        listened: _listened.contains((track.discNumber, track.position)),
        accentColor: widget.accentColor,
        onListenedToggle: () => _toggle(track),
      ),
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
    super.key,
  });

  final int itemId;
  final AlbumTrack track;
  final bool listened;
  final Color accentColor;
  final VoidCallback onListenedToggle;

  @override
  ConsumerState<_TrackTrackerRow> createState() => _TrackTrackerRowState();
}

class _TrackTrackerRowState extends ConsumerState<_TrackTrackerRow> {
  bool _editingNote = false;

  @override
  Widget build(BuildContext context) {
    final AlbumTrack track = widget.track;
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
              child: AlbumTrackRow(
                track: track,
                listened: widget.listened,
                accentColor: widget.accentColor,
                onTap: widget.onListenedToggle,
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
