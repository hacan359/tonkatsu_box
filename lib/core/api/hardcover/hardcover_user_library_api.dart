import '../../../shared/models/book.dart';
import 'hardcover_graphql_client.dart';
import 'hardcover_queries.dart';
import 'hardcover_types.dart';

class HardcoverUserLibraryApi {
  HardcoverUserLibraryApi(this._client);

  /// 500 rows per page keeps a multi-thousand-book library within a handful
  /// of requests — far under the 60/min limit.
  static const int pageSize = 500;

  final HardcoverGraphQLClient _client;

  /// Throws [HardcoverUserNotFoundException] when [username] does not exist.
  Future<void> ensureUserExists(String username) async {
    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.userLookup,
      variables: <String, dynamic>{'username': username},
      errorContext: 'Hardcover user lookup failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover user lookup failed');
    final Object? users = data['users'];
    if (users is! List<dynamic> || users.isEmpty) {
      throw HardcoverUserNotFoundException(username);
    }
  }

  /// Total `user_books` rows of [username] — for the progress bar. Counts
  /// raw rows (before `distinct_on`), so it is an upper bound.
  Future<int> countUserBooks(String username) async {
    final Map<String, dynamic> body = await _client.post(
      query: HardcoverQueries.userBooksCount,
      variables: <String, dynamic>{'username': username},
      errorContext: 'Hardcover library count failed',
    );
    final Map<String, dynamic> data =
        _client.ensureData(body, 'Hardcover library count failed');
    final Object? aggregate =
        (data['user_books_aggregate'] as Map<String, dynamic>?)?['aggregate'];
    if (aggregate is! Map<String, dynamic>) return 0;
    return (aggregate['count'] as num?)?.toInt() ?? 0;
  }

  /// Fetches the whole library of [username], one page per request. Only the
  /// public part of another user's library arrives; the token owner's own
  /// library comes back complete (including `private_notes`).
  Future<List<HardcoverUserBookEntry>> fetchUserBooks({
    required String username,
    void Function(int fetched, int total)? onProgress,
  }) async {
    await ensureUserExists(username);
    final int total = await countUserBooks(username);

    final List<HardcoverUserBookEntry> entries = <HardcoverUserBookEntry>[];
    int offset = 0;
    while (true) {
      final Map<String, dynamic> body = await _client.post(
        query: HardcoverQueries.userBooks,
        variables: <String, dynamic>{
          'username': username,
          'limit': pageSize,
          'offset': offset,
        },
        errorContext: 'Hardcover library fetch failed',
      );
      final Map<String, dynamic> data =
          _client.ensureData(body, 'Hardcover library fetch failed');

      final Object? rows = data['user_books'];
      final int pageLength = rows is List<dynamic> ? rows.length : 0;
      if (rows is List<dynamic>) {
        for (final Map<String, dynamic> row
            in rows.whereType<Map<String, dynamic>>()) {
          final HardcoverUserBookEntry? entry = _parseEntry(row);
          if (entry != null) entries.add(entry);
        }
      }

      offset += pageLength;
      onProgress?.call(offset.clamp(0, total), total);
      if (pageLength < pageSize) break;
    }
    return entries;
  }

  HardcoverUserBookEntry? _parseEntry(Map<String, dynamic> row) {
    final Object? book = row['book'];
    if (book is! Map<String, dynamic>) return null;

    final int statusId = (row['status_id'] as num?)?.toInt() ?? 0;
    if (statusId <= 0) return null;

    return HardcoverUserBookEntry(
      statusId: statusId,
      book: Book.fromHardcoverBook(book),
      rating: (row['rating'] as num?)?.toDouble(),
      readCount: (row['read_count'] as num?)?.toInt() ?? 0,
      firstStartedReadingDate: _date(row['first_started_reading_date']),
      firstReadDate: _date(row['first_read_date']),
      lastReadDate: _date(row['last_read_date']),
      dateAdded: _date(row['date_added']),
      review: _nonEmpty(row['review']),
      privateNotes: _nonEmpty(row['private_notes']),
      owned: row['owned'] as bool? ?? false,
    );
  }

  /// Dates arrive as `YYYY-MM-DD` strings.
  static DateTime? _date(Object? raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _nonEmpty(Object? raw) {
    if (raw is! String) return null;
    final String trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
