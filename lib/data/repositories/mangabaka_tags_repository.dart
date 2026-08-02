import 'package:core/models/mangabaka_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/mangabaka_api.dart';
import '../../core/database/dao/mangabaka_tag_dao.dart';
import '../../core/database/database_service.dart';

/// Loads the MangaBaka tag catalog with a SQLite-backed cache.
///
/// Cache is sticky: a non-empty cache is always returned without hitting the
/// API. A manual Refresh in the picker calls this with `forceRefresh: true`
/// — the only path that bypasses the cache. Mirrors `AniListTagsRepository`.
class MangaBakaTagsRepository {
  MangaBakaTagsRepository({
    required MangaBakaApi api,
    required MangaBakaTagDao dao,
  })  : _api = api,
        _dao = dao;

  final MangaBakaApi _api;
  final MangaBakaTagDao _dao;

  Future<List<MangaBakaTag>> getTags({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final List<MangaBakaTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
    }
    try {
      final List<MangaBakaTag> fresh = await _api.fetchTagCatalog();
      if (fresh.isNotEmpty) {
        await _dao.replaceAll(fresh);
        return fresh;
      }
    } on Object {
      final List<MangaBakaTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
    return _dao.getAll();
  }
}

final Provider<MangaBakaTagsRepository> mangaBakaTagsRepositoryProvider =
    Provider<MangaBakaTagsRepository>((Ref ref) {
  return MangaBakaTagsRepository(
    api: ref.watch(mangaBakaApiProvider),
    dao: ref.watch(mangaBakaTagDaoProvider),
  );
});

/// Cached MangaBaka tag catalog. Fetches on first watch if the SQLite cache
/// is empty.
final FutureProvider<List<MangaBakaTag>> mangaBakaTagsProvider =
    FutureProvider<List<MangaBakaTag>>((Ref ref) async {
  return ref.watch(mangaBakaTagsRepositoryProvider).getTags();
});
