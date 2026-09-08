import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';

import '../../../core/services/image_cache_service.dart';
import '../providers/recommendations_provider.dart';

/// Cache slot of a recommended title's poster, shared by every widget that
/// draws one so the hub preview and the full row hit the same cached file.
({ImageType type, String id}) recommendationCoverCache(RecommendedItem item) {
  return switch (item.mediaType) {
    MediaType.movie => (
        type: ImageType.moviePoster,
        id: coverImageId(
          mediaType: MediaType.movie,
          externalId: item.externalId,
          source: item.source,
        ),
      ),
    MediaType.anime => (
        type: ImageType.animeCover,
        id: coverImageId(
          mediaType: MediaType.anime,
          externalId: item.externalId,
          source: item.source,
        ),
      ),
    MediaType.manga => (
        type: ImageType.mangaCover,
        id: coverImageId(
          mediaType: MediaType.manga,
          externalId: item.externalId,
          source: item.source,
        ),
      ),
    _ => (
        type: ImageType.tvShowPoster,
        id: coverImageId(
          mediaType: MediaType.tvShow,
          externalId: item.externalId,
        ),
      ),
  };
}
