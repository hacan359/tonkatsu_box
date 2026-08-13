import 'package:core/models/audio_item.dart';
import 'package:core/models/audio_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/podcast_index_api.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/date_format_preset.dart';
import '../../../shared/widgets/audio_track_row.dart';
import '../../settings/providers/settings_provider.dart';
import 'item_details_sheet.dart';

/// Podcast detail sheet: feed info plus a preview of the newest episodes.
/// No editions strip — a feed has exactly one episode list.
class PodcastIndexSheet extends ConsumerStatefulWidget {
  const PodcastIndexSheet({
    required this.podcast,
    required this.onAddToCollection,
    super.key,
  });

  final AudioItem podcast;
  final VoidCallback onAddToCollection;

  /// Enough to show what the feed is about without paying for the full
  /// 1000-episode window the enrich step fetches on add.
  static const int previewEpisodes = 25;

  @override
  ConsumerState<PodcastIndexSheet> createState() => _PodcastIndexSheetState();
}

class _PodcastIndexSheetState extends ConsumerState<PodcastIndexSheet> {
  List<AudioTrack>? _episodes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<AudioTrack> episodes = await ref
          .read(podcastIndexApiProvider)
          .getEpisodes(
            widget.podcast.id,
            max: PodcastIndexSheet.previewEpisodes,
          );
      if (!mounted) return;
      setState(() => _episodes = episodes);
    } on Object {
      if (!mounted) return;
      setState(() => _episodes = const <AudioTrack>[]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ItemDetailsSheet.podcast(
      widget.podcast,
      onAddToCollection: widget.onAddToCollection,
      episodesSection: _buildEpisodes(context),
    );
  }

  Widget _buildEpisodes(BuildContext context) {
    final S l = S.of(context);
    final List<AudioTrack>? episodes = _episodes;
    if (episodes == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (episodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          l.podcastSheetNoEpisodes,
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
      );
    }

    final DateFormatPreset preset = DateFormatPreset.fromId(
      ref.watch(
        settingsNotifierProvider.select((SettingsState s) => s.dateFormat),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Text(l.podcastSheetEpisodes, style: AppTypography.h3),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final AudioTrack episode in episodes)
          AudioTrackRow(
            key: ValueKey<int>(episode.position),
            track: episode,
            positionLabel: episode.publishedAt != null
                ? preset.format(episode.publishedAt!, locale: l.localeName)
                : '',
            leadingWidth: kEpisodeDateLeadingWidth,
          ),
      ],
    );
  }
}
