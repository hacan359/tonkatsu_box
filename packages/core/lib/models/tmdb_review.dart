// Модель отзыва из TMDB.

/// Отзыв пользователя из TMDB API.
class TmdbReview {
  /// Создаёт экземпляр [TmdbReview].
  const TmdbReview({
    required this.author,
    required this.content,
    required this.createdAt,
    this.avatarPath,
    this.authorRating,
    this.url,
  });

  /// Создаёт [TmdbReview] из JSON ответа TMDB API.
  factory TmdbReview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? authorDetails =
        json['author_details'] as Map<String, dynamic>?;

    String? avatarPath;
    double? authorRating;

    if (authorDetails != null) {
      final String? rawAvatar = authorDetails['avatar_path'] as String?;
      if (rawAvatar != null && rawAvatar.isNotEmpty) {
        // Аватар может быть полным URL или путём TMDB
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

  /// Имя автора отзыва.
  final String author;

  /// URL аватара автора.
  final String? avatarPath;

  /// Оценка автора (0-10).
  final double? authorRating;

  /// Текст отзыва.
  final String content;

  /// Дата создания отзыва.
  final DateTime createdAt;

  /// URL отзыва на TMDB.
  final String? url;

  /// Возвращает отформатированный рейтинг автора.
  String? get formattedRating {
    if (authorRating == null) return null;
    return authorRating!.toStringAsFixed(0);
  }

  @override
  String toString() => 'TmdbReview(author: $author)';
}
