import 'package:core/models/album.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/listenbrainz_api.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/poster_grid_delegate.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../settings/providers/settings_provider.dart';

const int _maxFreshReleases = 40;

/// Fresh releases from ListenBrainz, most-listened first — best-effort, an
/// unreachable API renders the feed empty rather than as an error.
final AutoDisposeFutureProvider<List<Album>> musicFreshReleasesProvider =
    FutureProvider.autoDispose<List<Album>>((Ref ref) async {
  final List<FreshRelease> releases =
      await ref.watch(listenBrainzApiProvider).getFreshReleases();
  // A day-granularity feed: keep it for the session instead of refetching
  // on every re-entry of the music tab.
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

/// Discover state of the music tab (empty query): one "fresh releases" row
/// straight from ListenBrainz — no MusicBrainz request involved.
class MusicDiscoverFeed extends ConsumerWidget {
  const MusicDiscoverFeed({required this.onAlbumTap, super.key});

  final void Function(Album album) onAlbumTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    final AsyncValue<List<Album>> releases =
        ref.watch(musicFreshReleasesProvider);

    return releases.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, StackTrace _) => _empty(l),
      data: (List<Album> albums) {
        if (albums.isEmpty) return _empty(l);
        final double cardScale = ref.watch(
          settingsNotifierProvider.select((SettingsState s) => s.cardScale),
        );
        return CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.new_releases_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l.musicDiscoverFreshReleases,
                      style: AppTypography.h3
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid.builder(
                gridDelegate: posterGridDelegate(
                  width: MediaQuery.sizeOf(context).width,
                  cardScale: cardScale,
                ),
                itemCount: albums.length,
                itemBuilder: (BuildContext context, int index) {
                  final Album album = albums[index];
                  return MediaPosterCard(
                    key: ValueKey<String>(album.mbid),
                    variant: CardVariant.grid,
                    title: album.title,
                    subtitle: album.artistsString,
                    year: album.releaseYear,
                    imageUrl: album.coverUrl ?? '',
                    cacheImageType: ImageType.albumCover,
                    cacheImageId: coverImageId(
                      mediaType: MediaType.music,
                      externalId: album.id,
                      source: album.source,
                    ),
                    mediaType: MediaType.music,
                    placeholderIcon: Icons.album_outlined,
                    onTap: () => onAlbumTap(album),
                  );
                },
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
            ),
          ],
        );
      },
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
