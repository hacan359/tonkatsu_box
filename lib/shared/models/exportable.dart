/// Contract for an auto-widening export.
///
/// A guard test compares the keys of [toDb] and [toExport] through
/// [dbToExportKeyMapping] and fails when a field is added to the DB but not to
/// the export, forcing the developer to decide what happens to it.
mixin Exportable {
  /// [toDb] keys that are NOT exported (e.g. 'id', 'collection_id',
  /// 'added_at'). A new [toDb] field not listed here breaks the guard test.
  Set<String> get internalDbFields;

  /// Renames db_key to export_key when an exported field uses a different name
  /// than the DB column, e.g. `{'author_comment': 'comment'}`. Unlisted fields
  /// keep their original name.
  Map<String, String> get dbToExportKeyMapping => const <String, String>{};

  Map<String, dynamic> toDb();

  /// May transform values relative to [toDb] (date format, data encoding, enum
  /// values); the guard test only checks that the key set covers [toDb].
  Map<String, dynamic> toExport();
}
