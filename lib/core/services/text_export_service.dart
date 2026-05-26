import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';

/// Template-based text exporter for a collection.
///
/// Supports `{name}`, `{year}`, `{rating}`, `{myRating}`, `{platform}`,
/// `{status}`, `{genres}`, `{tags}`, `{notes}`, `{type}`, `{#}`. Empty tokens
/// and the surrounding separators are stripped automatically — see
/// [_removeTokenWithContext].
class TextExportService {
  static const String defaultTemplate = '{name} ({year})';

  static const List<String> availableTokens = <String>[
    'name',
    'year',
    'rating',
    'myRating',
    'platform',
    'status',
    'genres',
    'tags',
    'notes',
    'type',
    '#',
  ];

  String applyTemplate(
    String template,
    List<CollectionItem> items, {
    String animeMangaTitleLanguage = 'romaji',
  }) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(formatItem(
        template,
        items[i],
        i + 1,
        animeMangaTitleLanguage: animeMangaTitleLanguage,
      ));
    }
    return buffer.toString();
  }

  String formatItem(
    String template,
    CollectionItem item,
    int index, {
    String animeMangaTitleLanguage = 'romaji',
  }) {
    String line = template;
    final Map<String, String?> values = <String, String?>{
      'name': item.displayName(animeMangaTitleLanguage),
      'year': item.releaseYear?.toString(),
      'rating': _formatApiRating(item.apiRating),
      'myRating': item.userRating?.toString(),
      'platform': _platformOrNull(item),
      'status': _statusLabel(item.status),
      'genres': item.genresString,
      'tags': _animeMangaTags(item),
      'notes': item.userComment,
      'type': _mediaTypeLabel(item.mediaType),
      '#': index.toString(),
    };

    for (final MapEntry<String, String?> entry in values.entries) {
      final String token = '{${entry.key}}';
      if (!line.contains(token)) continue;

      if (entry.value != null && entry.value!.isNotEmpty) {
        line = line.replaceAll(token, entry.value!);
      } else {
        line = _removeTokenWithContext(line, token);
      }
    }

    return line.trim();
  }

  /// Strip an empty token together with the surrounding separator / bracket
  /// so a template like `"{name} ({year})"` collapses to `"{name}"` when
  /// year is missing instead of leaving an orphaned `"()"`.
  String _removeTokenWithContext(String line, String token) {
    final List<String> delimiters = <String>[
      ' — ',
      ' - ',
      ' · ',
      ' • ',
      ', ',
      ' | ',
    ];

    // Try removing "<separator><token>" or "<token><separator>" first.
    for (final String delim in delimiters) {
      if (line.contains('$delim$token')) {
        return line.replaceAll('$delim$token', '');
      }
      if (line.contains('$token$delim')) {
        return line.replaceAll('$token$delim', '');
      }
    }

    final String escaped = RegExp.escape(token);
    final RegExp parenPattern = RegExp(r'\s*\(' + escaped + r'\)');
    if (parenPattern.hasMatch(line)) {
      return line.replaceAll(parenPattern, '');
    }

    final RegExp bracketPattern = RegExp(r'\s*\[' + escaped + r'\]');
    if (bracketPattern.hasMatch(line)) {
      return line.replaceAll(bracketPattern, '');
    }

    return line.replaceAll(token, '');
  }

  String? _formatApiRating(double? rating) {
    if (rating == null) return null;
    if (rating == rating.roundToDouble()) {
      return rating.toInt().toString();
    }
    return rating.toStringAsFixed(1);
  }

  String? _platformOrNull(CollectionItem item) {
    if (item.platform == null) return null;
    return item.platform!.displayName;
  }

  String _statusLabel(ItemStatus status) {
    switch (status) {
      case ItemStatus.notStarted:
        return 'Not Started';
      case ItemStatus.inProgress:
        return 'In Progress';
      case ItemStatus.completed:
        return 'Completed';
      case ItemStatus.dropped:
        return 'Dropped';
      case ItemStatus.planned:
        return 'Planned';
    }
  }

  String _mediaTypeLabel(MediaType type) {
    switch (type) {
      case MediaType.game:
        return 'Game';
      case MediaType.movie:
        return 'Movie';
      case MediaType.tvShow:
        return 'TV Show';
      case MediaType.animation:
        return 'Animation';
      case MediaType.visualNovel:
        return 'Visual Novel';
      case MediaType.manga:
        return 'Manga';
      case MediaType.anime:
        return 'Anime';
      case MediaType.custom:
        return 'Custom';
    }
  }

  String? _animeMangaTags(CollectionItem item) {
    return switch (item.mediaType) {
      MediaType.anime => item.anime?.tagsString,
      MediaType.manga => item.manga?.tagsString,
      _ => null,
    };
  }
}

/// Sort mode for the text exporter.
enum TextExportSortMode {
  /// Source order from the collection.
  current,
  name,
  rating,
  year,
  addedDate,
}
