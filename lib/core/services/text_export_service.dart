// Сервис шаблонного экспорта коллекции в текст.

import '../../shared/models/collection_item.dart';
import '../../shared/models/item_status.dart';
import '../../shared/models/media_type.dart';

/// Сервис для экспорта коллекции в текстовый формат по шаблону.
///
/// Поддерживает токены `{name}`, `{year}`, `{rating}`, `{myRating}`,
/// `{platform}`, `{status}`, `{genres}`, `{notes}`, `{type}`, `{#}`.
/// Пустые токены и окружающие их разделители автоматически удаляются.
class TextExportService {
  /// Дефолтный шаблон (Quick Copy).
  static const String defaultTemplate = '{name} ({year})';

  /// Доступные токены для UI.
  static const List<String> availableTokens = <String>[
    'name',
    'year',
    'rating',
    'myRating',
    'platform',
    'status',
    'genres',
    'notes',
    'type',
    '#',
  ];

  /// Применяет шаблон ко всем элементам и возвращает текст.
  String applyTemplate(String template, List<CollectionItem> items) {
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      if (i > 0) buffer.writeln();
      buffer.write(formatItem(template, items[i], i + 1));
    }
    return buffer.toString();
  }

  /// Форматирует один элемент по шаблону.
  String formatItem(String template, CollectionItem item, int index) {
    // Подставляем значения токенов
    String line = template;

    // Собираем значения для каждого токена
    final Map<String, String?> values = <String, String?>{
      'name': item.itemName,
      'year': item.releaseYear?.toString(),
      'rating': _formatApiRating(item.apiRating),
      'myRating': item.userRating?.toString(),
      'platform': _platformOrNull(item),
      'status': _statusLabel(item.status),
      'genres': item.genresString,
      'notes': item.userComment,
      'type': _mediaTypeLabel(item.mediaType),
      '#': index.toString(),
    };

    // Заменяем токены с значениями
    for (final MapEntry<String, String?> entry in values.entries) {
      final String token = '{${entry.key}}';
      if (!line.contains(token)) continue;

      if (entry.value != null && entry.value!.isNotEmpty) {
        line = line.replaceAll(token, entry.value!);
      } else {
        // Токен пустой — удаляем токен + окружающие разделители
        line = _removeTokenWithContext(line, token);
      }
    }

    return line.trim();
  }

  /// Удаляет токен и лишние разделители/скобки вокруг.
  ///
  /// Примеры:
  /// - `"{name} ({year})"` при пустом year → `"{name}"`
  /// - `"{name} — {rating}"` при пустом rating → `"{name}"`
  /// - `"{name}, {genres}"` при пустом genres → `"{name}"`
  String _removeTokenWithContext(String line, String token) {
    // Паттерн: разделитель + токен (или токен + разделитель)
    // Разделители: " — ", " - ", " · ", ", ", " | ", пробел
    final List<String> delimiters = <String>[
      ' — ',
      ' - ',
      ' · ',
      ' • ',
      ', ',
      ' | ',
    ];

    // Попробуем удалить "разделитель + токен"
    for (final String delim in delimiters) {
      if (line.contains('$delim$token')) {
        return line.replaceAll('$delim$token', '');
      }
      if (line.contains('$token$delim')) {
        return line.replaceAll('$token$delim', '');
      }
    }

    // Скобки: "(...token...)" → ""
    final String escaped = RegExp.escape(token);
    final RegExp parenPattern = RegExp(r'\s*\(' + escaped + r'\)');
    if (parenPattern.hasMatch(line)) {
      return line.replaceAll(parenPattern, '');
    }

    // Квадратные скобки: "[...token...]" → ""
    final RegExp bracketPattern = RegExp(r'\s*\[' + escaped + r'\]');
    if (bracketPattern.hasMatch(line)) {
      return line.replaceAll(bracketPattern, '');
    }

    // Просто удаляем токен
    return line.replaceAll(token, '');
  }

  String? _formatApiRating(double? rating) {
    if (rating == null) return null;
    // Если дробная часть = 0, показываем целое число
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
}

/// Режим сортировки для текстового экспорта.
enum TextExportSortMode {
  /// Текущий порядок из коллекции.
  current,

  /// По названию A→Z.
  name,

  /// По рейтингу (высокий → низкий).
  rating,

  /// По году (новые → старые).
  year,

  /// По дате добавления (новые → старые).
  addedDate,
}
