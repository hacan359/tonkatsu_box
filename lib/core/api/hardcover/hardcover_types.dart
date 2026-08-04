import 'package:core/models/book.dart';

class HardcoverApiException implements Exception {
  const HardcoverApiException(this.message, {this.statusCode, this.detail});

  final String message;
  final int? statusCode;
  final String? detail;

  @override
  String toString() => 'HardcoverApiException: $message (status: $statusCode)';
}

/// 401 — the personal token is missing, invalid or expired. Hardcover tokens
/// live at most a year and are reset every January 1st, so this is a routine
/// condition: the user needs a fresh token from hardcover.app/account/api.
class HardcoverAuthException extends HardcoverApiException {
  const HardcoverAuthException({String? detail})
      : super(
          'Hardcover token is invalid or expired. '
          'Get a new one at hardcover.app/account/api',
          statusCode: 401,
          detail: detail,
        );
}

/// 429 — the 60 requests/minute limit was hit.
class HardcoverRateLimitException extends HardcoverApiException {
  const HardcoverRateLimitException({String? detail})
      : super(
          'Hardcover rate limit exceeded (60/min). Please try again later',
          statusCode: 429,
          detail: detail,
        );
}

class HardcoverUserNotFoundException extends HardcoverApiException {
  const HardcoverUserNotFoundException(String username)
      : super('Hardcover user "$username" not found', statusCode: 404);
}

/// One edition of a Hardcover book — its own cover, localized title and
/// bibliographic fields. Backs the edition picker strip and the refresh path.
class HardcoverEdition {
  const HardcoverEdition({
    required this.id,
    required this.bookId,
    required this.title,
    this.coverUrl,
    this.languageCode,
    this.publisher,
    this.pages,
    this.isbn10,
    this.isbn13,
    this.releaseYear,
    this.usersCount = 0,
  });

  factory HardcoverEdition.fromJson(Map<String, dynamic> json) {
    return HardcoverEdition(
      id: (json['id'] as num).toInt(),
      bookId: (json['book_id'] as num?)?.toInt() ?? 0,
      title: _string(json['title']) ?? '',
      coverUrl: _imageUrl(json['image']) ?? _imageUrl(json['cached_image']),
      languageCode: _nested(json['language'], 'code2'),
      publisher: _nested(json['publisher'], 'name'),
      pages: _positiveInt(json['pages']),
      isbn10: _string(json['isbn_10']),
      isbn13: _string(json['isbn_13']),
      releaseYear: _yearOf(json['release_date']),
      usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final int bookId;
  final String title;
  final String? coverUrl;

  /// ISO 639-1 code (`en`, `ru`, …); null when the catalog entry has no
  /// language set — common even for English editions.
  final String? languageCode;

  final String? publisher;
  final int? pages;
  final String? isbn10;
  final String? isbn13;
  final int? releaseYear;
  final int usersCount;

  static String? _string(Object? value) {
    if (value is! String) return null;
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _imageUrl(Object? image) =>
      image is Map<String, dynamic> ? _string(image['url']) : null;

  static String? _nested(Object? obj, String key) =>
      obj is Map<String, dynamic> ? _string(obj[key]) : null;

  static int? _positiveInt(Object? value) {
    final int? parsed = value is num ? value.toInt() : null;
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static int? _yearOf(Object? releaseDate) {
    if (releaseDate is! String || releaseDate.length < 4) return null;
    final int? year = int.tryParse(releaseDate.substring(0, 4));
    return year != null && year > 0 ? year : null;
  }
}

/// One `user_books` row: the user's personal fields plus the nested book.
class HardcoverUserBookEntry {
  const HardcoverUserBookEntry({
    required this.statusId,
    required this.book,
    this.rating,
    this.readCount = 0,
    this.firstStartedReadingDate,
    this.firstReadDate,
    this.lastReadDate,
    this.dateAdded,
    this.review,
    this.privateNotes,
    this.owned = false,
  });

  /// 1 Want to Read, 2 Currently Reading, 3 Read, 4 Paused,
  /// 5 Did Not Finish, 6 Ignored.
  final int statusId;

  final Book book;

  /// 0–5 with halves, or null if unset.
  final double? rating;

  final int readCount;

  final DateTime? firstStartedReadingDate;
  final DateTime? firstReadDate;
  final DateTime? lastReadDate;
  final DateTime? dateAdded;

  /// HTML with mention spans — strip before storing.
  final String? review;

  /// Only present for the token owner's own library; null on other users.
  final String? privateNotes;

  final bool owned;
}
