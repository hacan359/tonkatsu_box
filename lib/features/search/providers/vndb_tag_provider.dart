// Провайдер тегов (жанров) VNDB (статические данные из БД).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/models/visual_novel.dart';

/// Провайдер тегов VNDB (категория "content" — жанры).
///
/// Загружает теги из БД (предзаполнены миграцией v24).
final FutureProvider<List<VndbTag>> vndbTagsProvider =
    FutureProvider<List<VndbTag>>((Ref ref) async {
  final DatabaseService db = ref.watch(databaseServiceProvider);
  return db.getVndbTags();
});
