import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/manga.dart';
import '../../shared/models/mangabaka_tag.dart';
import 'mangabaka/mangabaka_http_client.dart';
import 'mangabaka/mangabaka_manga_api.dart';
import 'mangabaka/mangabaka_tags_api.dart';

export 'mangabaka/mangabaka_types.dart';

/// MangaBaka REST facade. See `mangabaka/README.md` for the layer breakdown.
class MangaBakaApi {
  MangaBakaApi({Dio? dio}) : _client = MangaBakaHttpClient(dio: dio) {
    _manga = MangaBakaMangaApi(_client);
    _tags = MangaBakaTagsApi(_client);
  }

  final MangaBakaHttpClient _client;
  late final MangaBakaMangaApi _manga;
  late final MangaBakaTagsApi _tags;

  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    String? type,
    String? status,
    List<String>? genres,
    List<String>? tags,
    String? contentRating,
    int page = 1,
    int perPage = 20,
  }) =>
      _manga.browseManga(
        query: query,
        type: type,
        status: status,
        genres: genres,
        tags: tags,
        contentRating: contentRating,
        page: page,
        perPage: perPage,
      );

  Future<Manga?> getById(int id) => _manga.getById(id);

  Future<List<Manga>> getRecommendations(int seedId, {int limit = 20}) =>
      _manga.getRecommendations(seedId, limit: limit);

  Future<List<MangaBakaTag>> fetchTagCatalog() => _tags.fetchTagCatalog();

  void dispose() => _client.dispose();
}

final Provider<MangaBakaApi> mangaBakaApiProvider =
    Provider<MangaBakaApi>((Ref ref) => MangaBakaApi());
