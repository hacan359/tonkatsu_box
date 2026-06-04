// VNDB tags (genres) provider, backed by static data in the DB.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/models/visual_novel.dart';

/// VNDB tags provider (the "content" category, i.e. genres).
///
/// Loads tags from the DB (seeded by migration v24).
final FutureProvider<List<VndbTag>> vndbTagsProvider =
    FutureProvider<List<VndbTag>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.visualNovelDao.getVndbTags();
});
