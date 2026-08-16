import 'package:core/models/visual_novel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// VNDB "content"-category tags (genres), loaded from the DB (seeded by
/// migration v24).
final FutureProvider<List<VndbTag>> vndbTagsProvider =
    FutureProvider<List<VndbTag>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.visualNovelDao.getVndbTags();
});
