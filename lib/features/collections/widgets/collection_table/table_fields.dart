import '../../../../l10n/app_localizations.dart';

/// trina_grid `field` ids of the collection table columns.
abstract final class TableFields {
  static const String drag = 'drag';
  static const String thumb = 'thumb';
  static const String name = 'name';
  static const String platform = 'platform';
  static const String type = 'type';
  static const String status = 'status';
  static const String progress = 'progress';
  static const String favorite = 'favorite';
  static const String rating = 'rating';
  static const String externalRating = 'externalRating';
  static const String year = 'year';
  static const String tags = 'tags';
}

/// Single ordered source of user-facing column labels for the columns menu
/// and the filter dialog; chrome columns (drag, thumbnail) never appear here.
Map<String, String> tableColumnLabels(S l) => <String, String>{
  TableFields.name: l.name,
  TableFields.platform: l.platform,
  TableFields.type: l.type,
  TableFields.status: l.status,
  TableFields.progress: l.progress,
  TableFields.favorite: l.favorite,
  TableFields.rating: l.rating,
  TableFields.externalRating: l.collectionTableExternalRating,
  TableFields.year: l.year,
  TableFields.tags: l.tagLabel,
};
