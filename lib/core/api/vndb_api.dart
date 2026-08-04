import 'package:core/models/visual_novel.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'vndb/vndb_http_client.dart';
import 'vndb/vndb_tags_api.dart';
import 'vndb/vndb_vn_api.dart';
export 'vndb/vndb_types.dart';

final Provider<VndbApi> vndbApiProvider = Provider<VndbApi>((Ref ref) {
  return VndbApi();
});

/// VNDB Kana API facade. See `vndb/README.md` for the layer breakdown.
class VndbApi {
  VndbApi({Dio? dio}) : _client = VndbHttpClient(dio: dio) {
    _vn = VndbVnApi(_client);
    _tags = VndbTagsApi(_client);
  }

  final VndbHttpClient _client;
  late final VndbVnApi _vn;
  late final VndbTagsApi _tags;

  Future<(List<VisualNovel>, bool hasMore)> searchVn({
    required String query,
    int page = 1,
    int results = 20,
  }) =>
      _vn.searchVn(query: query, page: page, results: results);

  Future<(List<VisualNovel>, bool hasMore, int totalPages)> browseVn({
    String? query,
    List<String>? tagIds,
    int? length,
    List<String>? langs,
    int? startYear,
    int? endYear,
    int? minRating,
    bool? hasAnime,
    String sort = 'rating',
    bool reverse = true,
    int page = 1,
    int results = 20,
  }) =>
      _vn.browseVn(
        query: query,
        tagIds: tagIds,
        length: length,
        langs: langs,
        startYear: startYear,
        endYear: endYear,
        minRating: minRating,
        hasAnime: hasAnime,
        sort: sort,
        reverse: reverse,
        page: page,
        results: results,
      );

  Future<VisualNovel?> getVnById(String id) => _vn.getVnById(id);

  Future<List<VisualNovel>> getVnByIds(List<String> ids) =>
      _vn.getVnByIds(ids);

  Future<List<VndbTag>> fetchTags() => _tags.fetchTags();

  void dispose() => _client.dispose();
}
