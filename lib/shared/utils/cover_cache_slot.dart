import 'package:core/models/data_source.dart';
import 'package:core/models/image_type.dart';
import 'package:core/models/media_type.dart';
import 'package:core/utils/cover_image_id.dart';

/// Cache slot of a title's cover; every widget drawing the same title must
/// use it so they all hit one cached file.
({ImageType type, String id}) coverCacheSlot({
  required MediaType mediaType,
  required int externalId,
  DataSource? source,
}) {
  final ImageType type = switch (mediaType) {
    MediaType.movie => ImageType.moviePoster,
    MediaType.anime => ImageType.animeCover,
    MediaType.manga => ImageType.mangaCover,
    MediaType.game => ImageType.gameCover,
    MediaType.audio => ImageType.audioCover,
    _ => ImageType.tvShowPoster,
  };
  return (
    type: type,
    id: coverImageId(
      mediaType: mediaType,
      externalId: externalId,
      source: source,
    ),
  );
}
