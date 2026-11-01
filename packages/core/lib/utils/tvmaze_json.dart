import 'json_list.dart';

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

/// `Creator` crew; only `/shows/{id}?embed[]=crew` carries it, search does not.
List<String>? tvMazeCreators(Map<String, dynamic> json) {
  final Object? embedded = json['_embedded'];
  final Object? crew =
      embedded is Map<String, dynamic> ? embedded['crew'] : null;
  if (crew is! List<dynamic>) return null;
  return distinctNames(<Object?>[
    for (final dynamic c in crew)
      if (c is Map<String, dynamic> && c['type'] == 'Creator')
        (c['person'] as Map<String, dynamic>?)?['name'],
  ]);
}

/// The broadcast network and the streaming channel, whichever are set.
List<String>? tvMazeNetworks(Map<String, dynamic> json) => distinctNames(
      <Object?>[
        for (final Object? n in <Object?>[json['network'], json['webChannel']])
          if (n is Map<String, dynamic>) n['name'],
      ],
    );
