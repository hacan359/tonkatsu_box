import 'package:core/database/dao/mangadex_tag_dao.dart';
import 'package:core/models/mangadex_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/mangadex_api.dart';
import '../../core/database/database_service.dart';

/// Sticky SQLite-backed tag cache (mirrors `MangaBakaTagsRepository`): a
/// non-empty cache always wins; only `forceRefresh` bypasses it.
class MangaDexTagsRepository {
  MangaDexTagsRepository({
    required MangaDexApi api,
    required MangaDexTagDao dao,
  })  : _api = api,
        _dao = dao;

  final MangaDexApi _api;
  final MangaDexTagDao _dao;

  Future<List<MangaDexTag>> getTags({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final List<MangaDexTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
    }
    try {
      final List<MangaDexTag> fresh = await _api.fetchTags();
      if (fresh.isNotEmpty) {
        await _dao.replaceAll(fresh);
        return fresh;
      }
    } on Object {
      final List<MangaDexTag> cached = await _dao.getAll();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
    return _dao.getAll();
  }
}

final Provider<MangaDexTagsRepository> mangaDexTagsRepositoryProvider =
    Provider<MangaDexTagsRepository>((Ref ref) {
  return MangaDexTagsRepository(
    api: ref.watch(mangaDexApiProvider),
    dao: ref.watch(mangaDexTagDaoProvider),
  );
});

/// Cached MangaDex tag catalog. Fetches on first watch if the SQLite cache is
/// empty.
final FutureProvider<List<MangaDexTag>> mangaDexTagsProvider =
    FutureProvider<List<MangaDexTag>>((Ref ref) async {
  return ref.watch(mangaDexTagsRepositoryProvider).getTags();
});
