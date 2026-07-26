import '../../../shared/constants/platform_features.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/mangabaka_api.dart';
import '../../../core/api/mangadex_api.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/collected_item_info.dart';
import '../../../shared/models/data_source.dart';
import '../../../shared/models/manga.dart';
import '../../../shared/models/media_type.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/utils/cover_image_id.dart';
import '../../../shared/widgets/media_poster_card.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../../search/widgets/item_details_sheet.dart';
import '../../settings/providers/settings_provider.dart'
    show settingsNotifierProvider;
import '../providers/collections_provider.dart';

/// Recommendations for a seed, routed by its source. `autoDispose` evicts the
/// entry when the card is left (and a first-fetch failure is not cached
/// forever); the record key carries `source` so same-`id`/different-source
/// seeds never collide.
final AutoDisposeFutureProviderFamily<List<Manga>, _MangaSeedKey>
    _mangaRecProvider =
    FutureProvider.autoDispose.family<List<Manga>, _MangaSeedKey>(
  (Ref ref, _MangaSeedKey seed) {
    switch (seed.source) {
      case DataSource.mangadex:
        if (seed.uuid.isEmpty) return Future<List<Manga>>.value(<Manga>[]);
        return ref.watch(mangaDexApiProvider).getRecommendations(seed.uuid);
      default:
        return ref.watch(mangaBakaApiProvider).getRecommendations(seed.id);
    }
  },
);

typedef _MangaSeedKey = ({DataSource source, int id, String uuid});

/// "Similar manga" row on a manga's detail page, seeded by the current title.
/// MangaBaka uses `/series/mix`, MangaDex uses `/manga/{id}/recommendation`;
/// mirrors the TMDB [RecommendationsSection]. Hidden while loading, on failure
/// or when nothing comes back.
class MangaSimilarsSection extends ConsumerWidget {
  const MangaSimilarsSection({
    required this.seed,
    this.onAddManga,
    super.key,
  });

  /// The manga being viewed; its `source` picks the recommendation backend.
  final Manga seed;

  /// Adds a tapped similar manga to a collection.
  final void Function(Manga manga)? onAddManga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _MangaSeedKey seedKey = (
      source: seed.source,
      id: seed.id,
      uuid: seed.source == DataSource.mangadex
          ? mangaDexUuidFromUrl(seed.externalUrl)
          : '',
    );
    final AsyncValue<List<Manga>> async = ref.watch(_mangaRecProvider(seedKey));

    final Map<int, List<CollectedItemInfo>> ownedMap =
        ref.watch(collectedMangaIdsProvider).valueOrNull ??
            const <int, List<CollectedItemInfo>>{};
    // Recommendations all share the seed's source, so match owned by source too
    // (a MangaBaka id can equal a MangaDex hash id).
    final Set<int> ownedIds = <int>{
      for (final MapEntry<int, List<CollectedItemInfo>> e in ownedMap.entries)
        if (e.value.any((CollectedItemInfo i) => i.source == seed.source))
          e.key,
    };
    final String titleLanguage =
        ref.watch(settingsNotifierProvider).animeMangaTitleLanguage;

    return async.when(
      data: (List<Manga> mangas) {
        if (mangas.isEmpty) return const SizedBox.shrink();
        return _MangaRow(
          title: S.of(context).recommendationsTitle,
          mangas: mangas,
          ownedIds: ownedIds,
          titleLanguage: titleLanguage,
          onTap: (Manga m) => _showManga(context, ref, m),
        );
      },
      loading: () => const _MangaRowShimmer(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showManga(BuildContext context, WidgetRef ref, Manga manga) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => ItemDetailsSheet.manga(
        manga,
        onAddToCollection: () => onAddManga?.call(manga),
        animeMangaTitleLanguage:
            ref.read(settingsNotifierProvider).animeMangaTitleLanguage,
      ),
    );
  }
}

class _MangaRow extends StatefulWidget {
  const _MangaRow({
    required this.title,
    required this.mangas,
    required this.ownedIds,
    required this.titleLanguage,
    required this.onTap,
  });

  final String title;
  final List<Manga> mangas;
  final Set<int> ownedIds;
  final String titleLanguage;
  final void Function(Manga manga) onTap;

  @override
  State<_MangaRow> createState() => _MangaRowState();
}

class _MangaRowState extends State<_MangaRow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    // Poster fills the card (2:3) + the list rows' vertical padding.
    final double rowHeight = posterWidth / AppSpacing.posterAspectRatio + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.title,
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ScrollableRowWithArrows(
            controller: _scrollController,
            height: rowHeight,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: widget.mangas.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final Manga manga = widget.mangas[index];
                return SizedBox(
                  width: posterWidth,
                  child: MediaPosterCard(
                    variant:
                        compact ? CardVariant.compact : CardVariant.grid,
                    title: manga.titleByLanguage(widget.titleLanguage),
                    imageUrl: manga.coverUrl ?? '',
                    cacheImageType: ImageType.mangaCover,
                    cacheImageId: coverImageId(
                      mediaType: MediaType.manga,
                      externalId: manga.id,
                      source: manga.source,
                    ),
                    year: manga.releaseYear,
                    apiRating: manga.rating10,
                    splitRatings: true,
                    isInCollection: widget.ownedIds.contains(manga.id),
                    placeholderIcon: Icons.auto_stories,
                    onTap: () => widget.onTap(manga),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MangaRowShimmer extends StatelessWidget {
  const _MangaRowShimmer();

  @override
  Widget build(BuildContext context) {
    final bool compact = isCompactScreen(context);
    final double posterWidth = compact ? 100 : 130;
    final double rowHeight = posterWidth / AppSpacing.posterAspectRatio + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 150,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, _) => SizedBox(
              width: posterWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: posterWidth * 0.7,
                    height: 12,
                    color: AppColors.surfaceLight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
