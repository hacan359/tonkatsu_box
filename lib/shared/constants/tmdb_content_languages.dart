// Список поддерживаемых языков контента TMDB.

import 'package:flutter/foundation.dart';

/// Локаль контента TMDB (`primary_translations`).
///
/// Используется для запросов `language=<code>` к TMDB API и
/// в UI выбора языка описаний фильмов/сериалов.
@immutable
class TmdbContentLanguage {
  /// Создаёт [TmdbContentLanguage].
  const TmdbContentLanguage({
    required this.code,
    required this.nativeName,
  });

  /// Код локали в формате IETF BCP 47, например `ru-RU`.
  final String code;

  /// Название языка на самом этом языке (например, `Русский`, `English`).
  final String nativeName;
}

/// Поддерживаемые языки контента TMDB.
///
/// Расширяется параллельно с локализацией интерфейса — пара локалей
/// (UI ↔ TMDB) обычно добавляется одним патчем.
const List<TmdbContentLanguage> kTmdbContentLanguages = <TmdbContentLanguage>[
  TmdbContentLanguage(code: 'en-US', nativeName: 'English'),
  TmdbContentLanguage(code: 'ru-RU', nativeName: 'Русский'),
];

/// Маппинг кода UI-локали → код языка контента TMDB по умолчанию.
///
/// Используется, чтобы при первом выборе UI-языка в визарде
/// автоматически выставить парный язык контента. Если UI-локали нет
/// в карте — возвращаем `en-US` как нейтральный fallback.
const Map<String, String> _kUiToContentLanguage = <String, String>{
  'en': 'en-US',
  'ru': 'ru-RU',
};

/// Возвращает дефолтный TMDB-код для UI-локали.
///
/// Расширяется одновременно с [kTmdbContentLanguages].
String defaultContentLanguageForUi(String uiLanguageCode) {
  return _kUiToContentLanguage[uiLanguageCode] ?? 'en-US';
}
