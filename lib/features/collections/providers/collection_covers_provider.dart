// Провайдер обложек для карточек коллекций.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';
import '../../../shared/models/cover_info.dart';

/// Провайдер для первых N обложек коллекции.
///
/// Легковесная альтернатива `collectionItemsNotifierProvider`:
/// загружает только URL обложек через JOIN-запрос, без полных моделей.
///
/// Ключ == null возвращает обложки uncategorized элементов.
final FutureProviderFamily<List<CoverInfo>, int?> collectionCoversProvider =
    FutureProvider.family<List<CoverInfo>, int?>(
  (Ref ref, int? collectionId) async {
    final DatabaseService db = ref.watch(databaseServiceProvider);
    return db.getCollectionCovers(collectionId, limit: 6);
  },
);
