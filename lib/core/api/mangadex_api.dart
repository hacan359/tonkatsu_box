import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/manga.dart';
import '../../shared/models/mangadex_tag.dart';
import 'mangadex/mangadex_http_client.dart';
import 'mangadex/mangadex_manga_api.dart';
import 'mangadex/mangadex_tags_api.dart';

export 'mangadex/mangadex_types.dart';

/// MangaDex REST facade (`https://api.mangadex.org`, no auth).
///
/// A manga provider alongside AniList / MangaBaka; items carry
/// `DataSource.mangadex` (set inside `Manga.fromMangaDex`) so they stay
/// distinct in the cache and collection.
class MangaDexApi {
  MangaDexApi({Dio? dio}) : _client = MangaDexHttpClient(dio: dio) {
    _manga = MangaDexMangaApi(_client);
    _tags = MangaDexTagsApi(_client);
  }

  final MangaDexHttpClient _client;
  late final MangaDexMangaApi _manga;
  late final MangaDexTagsApi _tags;

  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    List<String>? statuses,
    List<String>? demographics,
    List<String>? contentRatings,
    List<String>? includedTags,
    Map<String, String>? order,
    int page = 1,
    int perPage = 20,
  }) =>
      _manga.browseManga(
        query: query,
        statuses: statuses,
        demographics: demographics,
        contentRatings: contentRatings,
        includedTags: includedTags,
        order: order,
        page: page,
        perPage: perPage,
      );

  /// Detail by MangaDex UUID (recovered from the cached `externalUrl`).
  Future<Manga?> getByUuid(String uuid) => _manga.getByUuid(uuid);

  /// The tag catalog (genre / theme / format / content), for filter options.
  Future<List<MangaDexTag>> fetchTags() => _tags.fetchTags();

  void dispose() => _client.dispose();
}

final Provider<MangaDexApi> mangaDexApiProvider =
    Provider<MangaDexApi>((Ref ref) => MangaDexApi());
