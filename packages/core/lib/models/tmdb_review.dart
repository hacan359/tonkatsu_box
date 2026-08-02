
class TmdbReview {
  const TmdbReview({
    required this.author,
    required this.content,
    required this.createdAt,
    this.avatarPath,
    this.authorRating,
    this.url,
  });

  factory TmdbReview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? authorDetails =
        json['author_details'] as Map<String, dynamic>?;

    String? avatarPath;
    double? authorRating;

    if (authorDetails != null) {
      final String? rawAvatar = authorDetails['avatar_path'] as String?;
      if (rawAvatar != null && rawAvatar.isNotEmpty) {
        if (rawAvatar.startsWith('/http')) {
          avatarPath = rawAvatar.substring(1);
        } else {
          avatarPath = 'https://image.tmdb.org/t/p/w45$rawAvatar';
        }
      }
      authorRating = (authorDetails['rating'] as num?)?.toDouble();
    }

    return TmdbReview(
      author: (json['author'] as String?) ?? 'Anonymous',
      content: (json['content'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      avatarPath: avatarPath,
      authorRating: authorRating,
      url: json['url'] as String?,
    );
  }

  final String author;

  final String? avatarPath;

  /// TMDB scale is already 0–10.
  final double? authorRating;

  final String content;

  final DateTime createdAt;

  final String? url;

  String? get formattedRating {
    if (authorRating == null) return null;
    return authorRating!.toStringAsFixed(0);
  }

  @override
  String toString() => 'TmdbReview(author: $author)';
}
