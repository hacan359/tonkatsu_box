import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/anime.dart';
import '../../shared/models/manga.dart';
import 'kitsu/kitsu_anime_api.dart';
import 'kitsu/kitsu_http_client.dart';
import 'kitsu/kitsu_manga_api.dart';

export 'kitsu/kitsu_types.dart';

/// Kitsu JSON:API facade (`https://kitsu.io/api/edge`, no auth).
///
/// An anime + manga catalog; both carry `DataSource.kitsu`.
class KitsuApi {
  KitsuApi({Dio? dio}) : _client = KitsuHttpClient(dio: dio) {
    _manga = KitsuMangaApi(_client);
    _anime = KitsuAnimeApi(_client);
  }

  final KitsuHttpClient _client;
  late final KitsuMangaApi _manga;
  late final KitsuAnimeApi _anime;

  Future<(List<Manga>, bool hasMore, int totalPages)> browseManga({
    String? query,
    String? subtype,
    String? status,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) =>
      _manga.browseManga(
        query: query,
        subtype: subtype,
        status: status,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<Manga?> getMangaById(int id) => _manga.getById(id);

  Future<(List<Anime>, bool hasMore, int totalPages)> browseAnime({
    String? query,
    String? subtype,
    String? status,
    String? sort,
    int page = 1,
    int perPage = 20,
  }) =>
      _anime.browseAnime(
        query: query,
        subtype: subtype,
        status: status,
        sort: sort,
        page: page,
        perPage: perPage,
      );

  Future<Anime?> getAnimeById(int id) => _anime.getById(id);

  void dispose() => _client.dispose();
}

final Provider<KitsuApi> kitsuApiProvider =
    Provider<KitsuApi>((Ref ref) => KitsuApi());
