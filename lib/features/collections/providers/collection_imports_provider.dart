import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/database/database_service.dart';

final Logger _log = Logger('collectionImports');

final FutureProviderFamily<List<CollectionImport>, int>
collectionImportsProvider = FutureProvider.family<List<CollectionImport>, int>(
  (Ref ref, int collectionId) => ref
      .watch(databaseServiceProvider)
      .collectionImportDao
      .getForCollection(collectionId),
);

/// Call after a successful run. A null [collectionId] means the adapter wrote
/// nothing (empty library), so there is no run worth repeating.
Future<void> recordCollectionImport(
  WidgetRef ref, {
  required ImportSourceKind source,
  required int? collectionId,
  Map<String, Object?> options = const <String, Object?>{},
}) async {
  if (collectionId == null) return;
  // Callers fire and forget; a bookkeeping failure must not surface as an
  // unhandled error after an import that did succeed.
  try {
    await ref
        .read(databaseServiceProvider)
        .collectionImportDao
        .upsert(
          CollectionImport(
            collectionId: collectionId,
            source: source,
            options: options,
            lastRunAt: DateTime.now(),
          ),
        );
  } on Exception catch (e) {
    _log.warning('Failed to record ${source.key} import', e);
    return;
  }
  // Fire-and-forget callers may have left the screen by now.
  if (!ref.context.mounted) return;
  ref.invalidate(collectionImportsProvider(collectionId));
}
