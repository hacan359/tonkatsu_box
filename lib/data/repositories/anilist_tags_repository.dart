import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/anilist_api.dart';
import '../../core/database/dao/anilist_tag_dao.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/anilist_tag.dart';

/// Loads the AniList tag catalog with a SQLite-backed cache.
///
/// Cache is sticky: a non-empty cache is always returned without hitting the
/// API. A manual Refresh in the picker calls this with `forceRefresh: true`
/// — that's the only path that bypasses the cache.
class AniListTagsRepository {
  AniListTagsRepository({
    required AniListApi api,
    required AniListTagDao dao,
  })  : _api = api,
        _dao = dao;

  final AniListApi _api;
  final AniListTagDao _dao;

  Future<List<AniListTag>> getTags({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final List<AniListTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
    }
    try {
      final List<AniListTag> fresh = await _api.fetchTagCollection();
      if (fresh.isNotEmpty) {
        await _dao.replaceAll(fresh);
        return fresh;
      }
    } on Object {
      final List<AniListTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
    return _dao.getAll();
  }
}

final Provider<AniListTagsRepository> aniListTagsRepositoryProvider =
    Provider<AniListTagsRepository>((Ref ref) {
  return AniListTagsRepository(
    api: ref.watch(aniListApiProvider),
    dao: ref.watch(aniListTagDaoProvider),
  );
});

/// Cached list of AniList tags. Triggers an API fetch on first watch if the
/// SQLite cache is stale or empty.
final FutureProvider<List<AniListTag>> aniListTagsProvider =
    FutureProvider<List<AniListTag>>((Ref ref) async {
  return ref.watch(aniListTagsRepositoryProvider).getTags();
});
