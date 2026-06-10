import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/book.dart';
import 'fantlab/fantlab_editions.dart';
import 'fantlab/fantlab_http_client.dart';
import 'fantlab/fantlab_search_api.dart';
import 'fantlab/fantlab_works_api.dart';

export 'fantlab/fantlab_editions.dart';
export 'fantlab/fantlab_types.dart';

/// Fantlab REST facade. See `fantlab/README.md` for the layer breakdown.
class FantlabApi {
  FantlabApi({Dio? dio}) : _client = FantlabHttpClient(dio: dio) {
    _search = FantlabSearchApi(_client);
    _works = FantlabWorksApi(_client);
  }

  final FantlabHttpClient _client;
  late final FantlabSearchApi _search;
  late final FantlabWorksApi _works;

  /// Search works (`/search-works`). Server-fixed 25 results per page,
  /// relevance order, non-book types filtered out. [workType] (a Fantlab
  /// `name_eng`) narrows to one literary type.
  Future<(List<Book>, bool hasMore, int totalPages)> searchWorks({
    required String query,
    int page = 1,
    String? workType,
  }) =>
      _search.searchWorks(query: query, page: page, workType: workType);

  /// Full work by id (`/work/{id}/extended`), enriched with subjects, awards,
  /// series and edition data.
  Future<Book?> getWork(String id) => _works.getWork(id);

  /// Similar works for [id] (`/work/{id}/similars`).
  Future<List<Book>> getSimilars(String id) => _works.getSimilars(id);

  /// Editions of work [id] grouped by block (`/work/{id}/extended`).
  Future<List<FantlabEditionBlock>> getEditions(String id) =>
      _works.getEditions(id);

  void dispose() => _client.dispose();
}

final Provider<FantlabApi> fantlabApiProvider =
    Provider<FantlabApi>((Ref ref) => FantlabApi());
