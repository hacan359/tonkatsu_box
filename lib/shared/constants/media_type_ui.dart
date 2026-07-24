import '../../l10n/app_localizations.dart';
import '../models/media_type.dart';

/// Presentation extras for [MediaType].
extension MediaTypeUi on MediaType {
  String localizedLabel(S l) {
    switch (this) {
      case MediaType.game:
        return l.mediaTypeGame;
      case MediaType.movie:
        return l.mediaTypeMovie;
      case MediaType.tvShow:
        return l.mediaTypeTvShow;
      case MediaType.animation:
        return l.mediaTypeAnimation;
      case MediaType.visualNovel:
        return l.mediaTypeVisualNovel;
      case MediaType.manga:
        return l.mediaTypeManga;
      case MediaType.anime:
        return l.mediaTypeAnime;
      case MediaType.book:
        return l.mediaTypeBook;
      case MediaType.custom:
        return l.mediaTypeCustom;
    }
  }
}
