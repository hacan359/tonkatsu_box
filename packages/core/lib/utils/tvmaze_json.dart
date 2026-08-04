/// TVmaze `image` object → best available URL (`original`, else `medium`).
String? tvMazeImageUrl(Object? image) {
  if (image is! Map<String, dynamic>) return null;
  return (image['original'] as String?) ?? (image['medium'] as String?);
}

/// TVmaze `rating` object → `average` on the 0-10 scale.
double? tvMazeRating(Object? rating) {
  if (rating is! Map<String, dynamic>) return null;
  return (rating['average'] as num?)?.toDouble();
}
