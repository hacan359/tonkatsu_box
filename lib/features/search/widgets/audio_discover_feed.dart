import 'package:core/models/audio_item.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/listenbrainz_api.dart';
import '../../../core/api/podcast_index_api.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/poster_grid_delegate.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../settings/providers/settings_provider.dart';

const int _maxFreshReleases = 40;
const int _maxTrendingPodcasts = 20;

/// Fresh releases from ListenBrainz, most-listened first — best-effort, an
/// unreachable API renders the feed empty rather than as an error.
final AutoDisposeFutureProvider<List<AudioItem>> audioFreshReleasesProvider =
    FutureProvider.autoDispose<List<AudioItem>>((Ref ref) async {
  final List<FreshRelease> releases =
      await ref.watch(listenBrainzApiProvider).getFreshReleases();
  // A day-granularity feed: keep it for the session instead of refetching
  // on every re-entry of the audio tab.
  ref.keepAlive();
  final List<FreshRelease> albumsOnly = releases
      .where((FreshRelease r) => r.primaryType?.toLowerCase() == 'album')
      .toList()
    ..sort((FreshRelease a, FreshRelease b) =>
        (b.listenCount ?? 0).compareTo(a.listenCount ?? 0));
  return albumsOnly
      .take(_maxFreshReleases)
      .map((FreshRelease r) => r.toAlbum())
      .toList();
});

/// Trending podcasts in the app's language (English as the long tail).
/// Best-effort like the releases row — missing keys or a failure hide it.
final AutoDisposeFutureProviderFamily<List<AudioItem>, String>
    trendingPodcastsProvider =
    FutureProvider.autoDispose.family<List<AudioItem>, String>(
        (Ref ref, String appLanguage) async {
  final PodcastIndexApi api = ref.watch(podcastIndexApiProvider);
  // Keyless native builds would 401 on every tab entry — skip the request.
  // On web the proxy signs, so hasCredentials is legitimately false there.
  if (!kIsWebBuild && !api.hasCredentials) return const <AudioItem>[];
  try {
    final String lang = appLanguage == 'en' ? 'en' : '$appLanguage,en';
    final List<AudioItem> trending =
        await api.getTrending(max: _maxTrendingPodcasts, lang: lang);
    // Only a successful answer is worth pinning for the session; a failure
    // stays autoDispose so the next tab entry retries.
    ref.keepAlive();
    return trending;
  } on PodcastIndexApiException {
    return const <AudioItem>[];
  }
});

/// Rows come from ListenBrainz and Podcast Index, so neither costs a
/// MusicBrainz request; each hides itself when unavailable.
class AudioDiscoverFeed extends ConsumerWidget {
  const AudioDiscoverFeed({required this.onItemTap, super.key});

  final void Function(AudioItem item) onItemTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<AudioItem>> releases =
        ref.watch(audioFreshReleasesProvider);
    final String appLanguage = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.appLanguage),
    );
    final AsyncValue<List<AudioItem>> podcasts =
        ref.watch(trendingPodcastsProvider(appLanguage));

    if (releases.isLoading || podcasts.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<AudioItem> albums = releases.valueOrNull ?? const <AudioItem>[];
    final List<AudioItem> trending =
        podcasts.valueOrNull ?? const <AudioItem>[];
    if (albums.isEmpty && trending.isEmpty) return _empty(l);

    final double cardScale = ref.watch(
      settingsNotifierProvider.select((SettingsState s) => s.cardScale),
    );
    return CustomScrollView(
      slivers: <Widget>[
        if (albums.isNotEmpty) ...<Widget>[
          _header(Icons.new_releases_outlined, l.musicDiscoverFreshReleases),
          _grid(context, albums, cardScale, Icons.album_outlined),
        ],
        if (trending.isNotEmpty) ...<Widget>[
          _header(Icons.trending_up, l.podcastDiscoverTrending),
          _grid(context, trending, cardScale, Icons.podcasts_outlined),
        ],
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
        ),
      ],
    );
  }

  Widget _header(IconData icon, String title) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _grid(
    BuildContext context,
    List<AudioItem> items,
    double cardScale,
    IconData placeholderIcon,
  ) {
    final ({SliverGridDelegate delegate, double padding}) geometry =
        posterGridGeometry(context, cardScale: cardScale);
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: geometry.padding),
      sliver: SliverGrid.builder(
        gridDelegate: geometry.delegate,
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final AudioItem item = items[index];
          return MediaPosterCard(
            key: ValueKey<String>('${item.source.name}_${item.nativeId}'),
            variant: CardVariant.grid,
            title: item.title,
            subtitle: item.artistsString,
            year: item.releaseYear,
            imageUrl: item.coverUrl ?? '',
            cacheImageType: ImageType.audioCover,
            cacheImageId: coverImageId(
              mediaType: MediaType.audio,
              externalId: item.id,
              source: item.source,
            ),
            mediaType: MediaType.audio,
            typeLabelOverride: item.kind.cardLabel,
            placeholderIcon: placeholderIcon,
            onTap: () => onItemTap(item),
          );
        },
      ),
    );
  }

  Widget _empty(S l) => Center(
        child: Text(
          l.musicDiscoverUnavailable,
          style: AppTypography.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
      );
}
