import 'package:core/database/dao/mangabaka_tag_dao.dart';
import 'package:core/models/mangabaka_tag.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/mangabaka_api.dart';
import '../../core/database/database_service.dart';

/// Sticky SQLite-backed tag cache (mirrors `AniListTagsRepository`): a
/// non-empty cache always wins; only `forceRefresh: true` bypasses it.
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
