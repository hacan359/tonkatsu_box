import '../../../../shared/models/item_status.dart';
import '../../../../shared/models/media_type.dart';

/// Field keys of the custom-cards import schema, shared by the JSON and CSV
/// parsers and the downloadable templates.
abstract final class CustomCardFields {
  static const String title = 'title';
  static const String type = 'type';
  static const String altTitle = 'alt_title';
  static const String description = 'description';
  static const String year = 'year';
  static const String genres = 'genres';
  static const String link = 'link';
  static const String cover = 'cover';
  static const String platform = 'platform';
  static const String format = 'format';
  static const String unitTotal = 'unit_total';
  static const String unitGroupTotal = 'unit_group_total';
  static const String status = 'status';
  static const String rating = 'rating';
  static const String comment = 'comment';
  static const String rewatchCount = 'rewatch_count';
  static const String startedAt = 'started_at';
  static const String completedAt = 'completed_at';
  static const String timeSpentMinutes = 'time_spent_minutes';
  static const String tags = 'tags';
  static const String favorite = 'favorite';
  static const String currentEpisode = 'current_episode';
  static const String currentSeason = 'current_season';

  /// Canonical column order for the CSV template and previews.
  static const List<String> ordered = <String>[
    title,
    type,
    altTitle,
    description,
    year,
    genres,
    link,
    cover,
    platform,
    format,
    unitTotal,
    unitGroupTotal,
    status,
    rating,
    comment,
    rewatchCount,
    startedAt,
    completedAt,
    timeSpentMinutes,
    favorite,
    currentEpisode,
    currentSeason,
    tags,
  ];

  /// Card types a file may declare. `custom` itself is not accepted: the card
  /// is always stored as a custom item, `type` only picks how it masquerades.
  static const List<MediaType> allowedTypes = <MediaType>[
    MediaType.game,
    MediaType.movie,
    MediaType.tvShow,
    MediaType.animation,
    MediaType.visualNovel,
    MediaType.manga,
    MediaType.anime,
    MediaType.book,
  ];
}

/// Why a row (or the whole file) failed validation.
enum CustomCardIssueCode {
  /// A JSON array element is not an object.
  notAnObject,

  /// `title` is missing or blank.
  missingTitle,

  /// `type` is missing or blank.
  missingType,

  /// `type` is not one of [CustomCardFields.allowedTypes].
  unknownType,

  /// A numeric field does not parse or is out of its valid range.
  invalidNumber,

  /// `status` is not a known [ItemStatus] value.
  unknownStatus,

  /// `format` is not a known manga/anime format code.
  unknownFormat,

  /// `format` was given for a type that has no formats (not manga/anime).
  formatNotApplicable,

  /// `cover` is not an http(s) URL.
  invalidCoverUrl,

  /// A date field is not an ISO `YYYY-MM-DD` date.
  invalidDate,

  /// `favorite` is not a boolean (`true`/`false`/`1`/`0`).
  invalidBool,
}

extension CustomCardIssueCodeX on CustomCardIssueCode {
  /// Blocking issues make the row unimportable; soft issues only drop the
  /// offending field, so the row is still built without it.
  bool get isBlocking =>
      this == CustomCardIssueCode.notAnObject ||
      this == CustomCardIssueCode.missingTitle ||
      this == CustomCardIssueCode.missingType ||
      this == CustomCardIssueCode.unknownType;
}

/// One validation problem of a parsed row: the [code] plus the offending
/// [field]/[value] for the error message.
class CustomCardIssue {
  const CustomCardIssue(this.code, {this.field, this.value});

  final CustomCardIssueCode code;
  final String? field;
  final String? value;
}

/// A fully validated card from the import file. Field semantics mirror
/// `CustomMedia` plus the personal columns of `collection_items`.
class CustomCardEntry {
  const CustomCardEntry({
    required this.title,
    required this.type,
    this.altTitle,
    this.description,
    this.year,
    this.genres,
    this.link,
    this.coverUrl,
    this.platform,
    this.format,
    this.unitTotal,
    this.unitGroupTotal,
    this.status,
    this.rating,
    this.comment,
    this.rewatchCount,
    this.startedAt,
    this.completedAt,
    this.timeSpentMinutes,
    this.favorite,
    this.currentEpisode,
    this.currentSeason,
    this.tags = const <String>[],
  });

  final String title;

  /// Display type of the created custom card (never [MediaType.custom]).
  final MediaType type;

  final String? altTitle;
  final String? description;
  final int? year;

  /// Comma-separated genre list, stored verbatim.
  final String? genres;

  /// External page URL (`external_url` on the card).
  final String? link;

  /// Remote cover URL, downloaded into the image cache after import.
  final String? coverUrl;

  /// Raw platform text; matched against the platform catalog at import time.
  final String? platform;

  /// Canonical (upper-cased) manga/anime format code.
  final String? format;

  final int? unitTotal;
  final int? unitGroupTotal;

  final ItemStatus? status;
  final double? rating;

  /// Personal note ("My Note", `user_comment` on the item).
  final String? comment;

  final int? rewatchCount;

  /// Explicit activity dates; they win over the dates the status implies.
  final DateTime? startedAt;
  final DateTime? completedAt;

  final int? timeSpentMinutes;

  final bool? favorite;

  /// Progress positions against [unitTotal] / [unitGroupTotal].
  final int? currentEpisode;
  final int? currentSeason;

  /// Global tag names; missing tags are created at import time.
  final List<String> tags;
}

/// One row of the parsed file: either a valid [entry] or the [issues] that
/// disqualified it. [index] is the 1-based data row / array element number.
class CustomCardRow {
  const CustomCardRow({
    required this.index,
    this.entry,
    this.issues = const <CustomCardIssue>[],
    this.sourceTitle,
  });

  final int index;
  final CustomCardEntry? entry;
  final List<CustomCardIssue> issues;

  /// Raw title text for labeling invalid rows in the preview (may be null
  /// when the row has no readable title at all).
  final String? sourceTitle;

  bool get isValid => entry != null;
}

/// Why the file as a whole cannot be parsed.
enum CustomCardsParseErrorCode {
  emptyFile,
  invalidJson,
  missingRequiredColumns,
}

/// Raised when the import file cannot be parsed at all (broken JSON, empty
/// file, CSV without the required header columns).
class CustomCardsParseException implements Exception {
  const CustomCardsParseException(this.code);

  final CustomCardsParseErrorCode code;

  @override
  String toString() => 'CustomCardsParseException: ${code.name}';
}
