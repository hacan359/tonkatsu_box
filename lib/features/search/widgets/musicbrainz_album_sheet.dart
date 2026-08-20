import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/musicbrainz_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/audio_track_row.dart';
import 'item_details_sheet.dart';

/// AudioItem detail sheet: editions strip plus the selected edition's tracks,
/// reported via [onReleaseChanged] so an add saves them without re-fetching.
class MusicBrainzAlbumSheet extends ConsumerStatefulWidget {
  const MusicBrainzAlbumSheet({
    required this.album,
    required this.onAddToCollection,
    required this.onReleaseChanged,
    super.key,
  });

  final AudioItem album;
  final VoidCallback onAddToCollection;
  final void Function(
    String albumMbid,
    MusicBrainzRelease? release,
    List<AudioTrack>? tracks,
  ) onReleaseChanged;

  @override
  ConsumerState<MusicBrainzAlbumSheet> createState() =>
      _MusicBrainzAlbumSheetState();
}

class _MusicBrainzAlbumSheetState extends ConsumerState<MusicBrainzAlbumSheet> {
  List<MusicBrainzRelease>? _releases;
  MusicBrainzRelease? _selected;
  List<AudioTrack>? _tracks;

  @override
  void initState() {
    super.initState();
    // Clear any selection left over from a previously opened sheet.
    widget.onReleaseChanged(widget.album.nativeId, null, null);
    _load();
  }

  Future<void> _load() async {
    final MusicBrainzApi api = ref.read(musicBrainzApiProvider);
    try {
      final List<MusicBrainzRelease> releases =
          await api.getReleasesOrAny(widget.album.nativeId);
      if (!mounted) return;
      final MusicBrainzRelease? first =
          releases.isEmpty ? null : releases.first;
      setState(() {
        _releases = releases;
        _selected = first;
      });
      if (first != null) {
        widget.onReleaseChanged(widget.album.nativeId, first, null);
        await _loadTracks(first);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _releases = const <MusicBrainzRelease>[]);
    }
  }

  Future<void> _loadTracks(MusicBrainzRelease release) async {
    setState(() => _tracks = null);
    try {
      final List<AudioTrack> tracks = await ref
          .read(musicBrainzApiProvider)
          .getReleaseTracks(release.mbid, audioId: widget.album.id);
      if (!mounted || _selected?.mbid != release.mbid) return;
      setState(() => _tracks = tracks);
      widget.onReleaseChanged(widget.album.nativeId, release, tracks);
    } on Object {
      if (!mounted) return;
      setState(() => _tracks = const <AudioTrack>[]);
    }
  }

  void _onReleasePicked(MusicBrainzRelease release) {
    if (_selected?.mbid == release.mbid) return;
    setState(() => _selected = release);
    widget.onReleaseChanged(widget.album.nativeId, release, null);
    _loadTracks(release);
  }

  @override
  Widget build(BuildContext context) {
    return ItemDetailsSheet.album(
      widget.album,
      onAddToCollection: widget.onAddToCollection,
      editionsSection: _buildMusicSections(context),
    );
  }

  Widget _buildMusicSections(BuildContext context) {
    final S l = S.of(context);
    final List<MusicBrainzRelease>? releases = _releases;

    if (releases == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (releases.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          l.musicSheetEditionsUnavailable,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (releases.length > 1) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l.musicSheetEditions, style: AppTypography.h3),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: releases.length,
              separatorBuilder: (BuildContext _, int _) =>
                  const SizedBox(width: AppSpacing.xs),
              itemBuilder: (BuildContext context, int index) {
                final MusicBrainzRelease release = releases[index];
                return ChoiceChip(
                  key: ValueKey<String>(release.mbid),
                  label: Text(_releaseLabel(release)),
                  selected: release.mbid == _selected?.mbid,
                  onSelected: (bool _) => _onReleasePicked(release),
                );
              },
            ),
          ),
        ],
        if (_selected != null) _buildTrackList(l),
      ],
    );
  }

  Widget _buildTrackList(S l) {
    final List<AudioTrack>? tracks = _tracks;
    if (tracks == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (tracks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(l.musicSheetTracks, style: AppTypography.h3),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...buildAudioTrackList(
          tracks: tracks,
          discLabel: (int discNumber) => l.musicSheetDisc(discNumber),
          rowBuilder: (AudioTrack track) => AudioTrackRow(
            key: ValueKey<String>('${track.discNumber}_${track.position}'),
            track: track,
          ),
        ),
      ],
    );
  }

  static String _releaseLabel(MusicBrainzRelease release) {
    final List<String> parts = <String>[
      if (release.date != null && release.date!.length >= 4)
        release.date!.substring(0, 4),
      if (release.format != null) release.format!,
      if (release.country != null) release.country!,
    ];
    return parts.isEmpty ? release.title : parts.join(' · ');
  }
}
