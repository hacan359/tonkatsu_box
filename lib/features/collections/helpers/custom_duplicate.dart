import 'package:core/models/collection_item.dart';
import 'package:core/models/custom_media.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/json_list.dart';

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
    // A local marker names another card's file; the duplicate gets the bytes
    // instead, or no cover where none were read (web).
    coverUrl: coverUrl != null &&
            coverUrl.isNotEmpty &&
            !CustomMedia.isLocalCover(coverUrl)
        ? coverUrl
        : null,
    year: item.releaseYear,
    genres: item.genresString,
    // Each item holds one sub-model, so at most one list is non-empty.
    authors: distinctNames(<String>[
      ...?item.customMedia?.authors,
      ...?item.movie?.directors,
      ...?item.tvShow?.creators,
      ...?item.game?.developers,
      ...?item.book?.authors,
      ...?item.manga?.authors,
      ...?item.audioItem?.artists,
      ...?item.visualNovel?.developers,
      ...?item.anime?.studios,
    ]),
    platformName: type == MediaType.game ? item.platform?.displayName : null,
    platformId: type == MediaType.game ? item.effectivePlatformId : null,
    format: item.formatCode,
    unitTotal:
        item.totalEpisodes ?? item.manga?.chapters ?? item.book?.pageCount,
    unitGroupTotal: item.totalSeasons ?? item.manga?.volumes,
    externalUrl: item.externalUrl,
  );
}
