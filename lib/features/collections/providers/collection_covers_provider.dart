import 'package:core/models/cover_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_service.dart';

/// Lightweight alternative to `collectionItemsNotifierProvider`: loads only
/// cover URLs via a JOIN, no full models. Key == null = uncategorized items.
final FutureProviderFamily<List<CoverInfo>, int?> collectionCoversProvider =
    FutureProvider.family<List<CoverInfo>, int?>(
  (Ref ref, int? collectionId) async {
    final DatabaseService db = ref.watch(databaseServiceProvider);
    return db.getCollectionCovers(collectionId, limit: 9);
  },
);
