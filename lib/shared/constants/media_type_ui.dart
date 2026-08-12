import 'package:core/models/media_type.dart';

import '../../l10n/app_localizations.dart';

/// Presentation extras for [MediaType].
extension MediaTypeUi on MediaType {
  /// Plural label ("Games", "TV Shows"); invariant types reuse the singular.
  String localizedPluralLabel(S l) {
    switch (this) {
      case MediaType.game:
        return l.collectionFilterGames;
      case MediaType.movie:
        return l.collectionFilterMovies;
      case MediaType.tvShow:
        return l.collectionFilterTvShows;
      case MediaType.visualNovel:
        return l.collectionFilterVisualNovels;
      case MediaType.book:
        return l.collectionFilterBooks;
      default:
        return localizedLabel(l);
    }
  }

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
      case MediaType.music:
        return l.mediaTypeMusic;
      case MediaType.custom:
        return l.mediaTypeCustom;
    }
  }
}
