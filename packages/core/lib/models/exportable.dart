/// A guard test compares [toDb] and [toExport] keys through
/// [dbToExportKeyMapping] and fails when a new DB field is not exported.
mixin Exportable {
  /// [toDb] keys that are NOT exported (e.g. 'id', 'collection_id',
  /// 'added_at'). A new [toDb] field not listed here breaks the guard test.
  Set<String> get internalDbFields;

  /// Renames a db key when the export uses a different one, e.g.
  /// `{'author_comment': 'comment'}`. Unlisted fields keep their name.
  Map<String, String> get dbToExportKeyMapping => const <String, String>{};

  Map<String, dynamic> toDb();

  /// May transform values relative to [toDb] (date format, data encoding, enum
  /// values); the guard test only checks that the key set covers [toDb].
  Map<String, dynamic> toExport();
}
