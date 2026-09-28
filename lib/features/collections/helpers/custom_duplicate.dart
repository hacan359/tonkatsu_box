import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';

/// Only the card's metadata: status, rating, note and episode marks stay
/// behind, so the duplicate starts like a freshly added item.
CustomMedia customDraftFromItem(CollectionItem item, {required String title}) {
  final MediaType type = item.displayMediaType;
  final String? original = item.movie?.originalTitle ??
      item.tvShow?.originalTitle ??
      item.book?.originalTitle ??
      item.visualNovel?.altTitle ??
      item.anime?.titleNative ??
      item.manga?.titleNative;
  final String? coverUrl = item.coverUrl;
  return CustomMedia(
    id: 0,
    title: title,
    displayType: type,
    altTitle: original != null && original.isNotEmpty && original != title
        ? original
        : null,
    description: item.itemDescription,
    coverUrl: coverUrl != null && coverUrl.isNotEmpty ? coverUrl : null,
    year: item.releaseYear,
    genres: item.genresString,
    platformName: type == MediaType.game ? item.platform?.displayName : null,
    platformId: type == MediaType.game ? item.effectivePlatformId : null,
    format: item.formatCode,
    unitTotal:
        item.totalEpisodes ?? item.manga?.chapters ?? item.book?.pageCount,
    unitGroupTotal: item.totalSeasons ?? item.manga?.volumes,
    externalUrl: item.externalUrl,
  );
}
