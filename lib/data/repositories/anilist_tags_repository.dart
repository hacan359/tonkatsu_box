import 'package:core/database/dao/anilist_tag_dao.dart';
import 'package:core/models/anilist_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/anilist_api.dart';
import '../../core/database/database_service.dart';

/// Sticky SQLite-backed tag cache: a non-empty cache always wins; only the
/// picker's manual Refresh (`forceRefresh: true`) bypasses it.
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
