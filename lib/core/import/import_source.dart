import 'package:core/models/universal_import_result.dart';

import 'import_progress.dart';

/// Base options for an import run. Sources extend this with their own inputs
/// (file path, username, token, feature toggles).
abstract class ImportOptions {
  const ImportOptions({this.collectionId});

  /// Target collection id; `null` means "create a new collection".
  final int? collectionId;
}

/// One port, many adapters: the shared write-side and matchers are injected
/// into each adapter, not inherited — the port only fixes the I/O shape.
abstract interface class ImportSource {
  /// Human-readable source name, also used as the wishlist import tag.
  String get displayName;

  /// Runs the import. [options] is the adapter's own [ImportOptions] subtype
  /// (declared `covariant` so each adapter narrows it to its concrete type).
  Future<UniversalImportResult> import(
    covariant ImportOptions options, {
    ImportProgressCallback? onProgress,
  });
}
