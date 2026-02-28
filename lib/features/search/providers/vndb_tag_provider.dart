// Провайдер тегов (жанров) VNDB с кэшированием.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/vndb_api.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/models/visual_novel.dart';

/// Провайдер тегов VNDB (категория "content" — жанры).
///
/// Стратегия кэширования:
/// 1. Сначала из SQLite кэша (vndb_tags)
/// 2. Если пусто — загружает из API и кэширует
final FutureProvider<List<VndbTag>> vndbTagsProvider =
    FutureProvider<List<VndbTag>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  final VndbApi api = ref.watch(vndbApiProvider);

  // Сначала из кэша
  final List<VndbTag> cached = await db.getVndbTags();
  if (cached.isNotEmpty) return cached;

  // Если пусто — из API
  final List<VndbTag> tags = await api.fetchTags();
  if (tags.isNotEmpty) {
    await db.cacheVndbTags(tags);
  }
  return tags;
});
