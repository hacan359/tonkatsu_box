import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';

/// One file row as a source sees it. [platformId] is the IGDB filter only;
/// the catalog lookup that produced it happens upstream.
class TitleQuery {
  const TitleQuery({
    required this.title,
    this.altTitle,
    this.year,
    this.platformId,
  });

  final String title;
  final String? altTitle;
  final int? year;
  final int? platformId;

  List<String> get titles => <String>[title, ?altTitle];
}

/// A search hit reduced to what matching and writing need; [media] is the
/// fetched model (Movie, TvShow, Game, Anime, Manga, Book, VisualNovel).
class LookupCandidate {
  const LookupCandidate({
    required this.media,
    required this.mediaType,
    required this.externalId,
    required this.source,
    required this.titles,
    this.year,
    this.platformId,
    this.platformIds = const <int>[],
    this.coverUrl,
  });

  final Object media;

  /// [MediaType.animation] for TMDB animated titles, whatever the model is.
  final MediaType mediaType;

  final int externalId;
  final DataSource source;
  final List<String?> titles;
  final int? year;

  /// `AnimationSource.*` for animation; games get theirs from [platformIds].
  final int? platformId;

  final List<int> platformIds;
  final String? coverUrl;
}

typedef TitleSearch = Future<List<LookupCandidate>> Function(TitleQuery query);

class LookupSource {
  const LookupSource({
    required this.source,
    required this.search,
    required this.isRateLimit,
  });

  final DataSource source;
  final TitleSearch search;
  final bool Function(Object error) isRateLimit;
}
