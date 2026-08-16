import 'package:core/models/collection_item.dart';
import 'package:core/utils/anime_manga_title_language.dart';

import '../../l10n/app_localizations.dart';

/// Template-based text exporter; empty tokens and their surrounding
/// separators are stripped automatically — see [_removeTokenWithContext].
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
    'link',
    '#',
  ];

  String applyTemplate(
    String template,
    List<CollectionItem> items, {
    String animeMangaTitleLanguage = AnimeMangaTitleLanguage.defaultId,
    Map<int, String> tagsByItemId = const <int, String>{},
  }) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(formatItem(
        template,
        items[i],
        i + 1,
        animeMangaTitleLanguage: animeMangaTitleLanguage,
        tagsByItemId: tagsByItemId,
      ));
    }
    return buffer.toString();
  }

  /// [tagsByItemId] carries the user's global tags (item id → joined names),
  /// resolved by the caller since tag state lives in Riverpod providers.
  String formatItem(
    String template,
    CollectionItem item,
    int index, {
    String animeMangaTitleLanguage = AnimeMangaTitleLanguage.defaultId,
    Map<int, String> tagsByItemId = const <int, String>{},
  }) {
    String line = template;
    final Map<String, String?> values = <String, String?>{
      'name': item.displayName(animeMangaTitleLanguage),
      'year': item.releaseYear?.toString(),
      'rating': _formatApiRating(item.apiRating),
      'myRating': item.userRating?.toStringAsFixed(1),
      'platform': _platformOrNull(item),
      'status': item.status.displayLabel,
      'genres': item.genresString,
      'tags': tagsByItemId[item.id],
      'notes': item.userComment,
      'type': item.displayMediaType.displayLabel,
      'link': item.externalUrl,
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

  /// Strip an empty token with its separator/bracket so `"{name} ({year})"`
  /// leaves no orphaned `"()"` when year is missing.
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
}

enum TextExportSortMode {
  /// Source order from the collection.
  current,
  name,
  rating,
  year,
  addedDate;

  String localizedLabel(S l) => switch (this) {
        TextExportSortMode.current => l.textExportSortCurrent,
        TextExportSortMode.name => l.textExportSortName,
        TextExportSortMode.rating => l.allItemsRatingDesc,
        TextExportSortMode.year => l.textExportSortYear,
        TextExportSortMode.addedDate => l.textExportSortAdded,
      };
}
