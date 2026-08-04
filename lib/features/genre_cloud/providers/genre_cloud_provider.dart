// Riverpod glue: the whole library's items for the preference cloud to aggregate.

import 'package:core/models/collection_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/all_items_provider.dart';

/// Items the preference cloud is built from (the whole library). Aggregation and
/// media-type filtering are done by the screen so the legend can re-filter
/// without re-reading.
final Provider<AsyncValue<List<CollectionItem>>> genreCloudItemsProvider =
    Provider<AsyncValue<List<CollectionItem>>>(
  (Ref ref) => ref.watch(allItemsNotifierProvider),
);
