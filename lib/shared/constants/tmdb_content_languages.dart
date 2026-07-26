import 'package:flutter/foundation.dart';

import '../utils/anime_manga_title_language.dart';

/// TMDB content locale: the `language=` request value and its native name.
@immutable
class TmdbContentLanguage {
  const TmdbContentLanguage({
    required this.code,
    required this.nativeName,
  });

  /// IETF BCP 47 locale code, e.g. `ru-RU`.
  final String code;

  /// Language name in that language itself (`Русский`, `English`).
  final String nativeName;
}

/// Curated from TMDB `/configuration/primary_translations`, sorted by code.
const List<TmdbContentLanguage> kTmdbContentLanguages = <TmdbContentLanguage>[
  TmdbContentLanguage(code: 'ar-SA', nativeName: 'العربية'),
  TmdbContentLanguage(code: 'be-BY', nativeName: 'Беларуская'),
  TmdbContentLanguage(code: 'bg-BG', nativeName: 'Български'),
  TmdbContentLanguage(code: 'ca-ES', nativeName: 'Català'),
  TmdbContentLanguage(code: 'cs-CZ', nativeName: 'Čeština'),
  TmdbContentLanguage(code: 'da-DK', nativeName: 'Dansk'),
  TmdbContentLanguage(code: 'de-DE', nativeName: 'Deutsch'),
  TmdbContentLanguage(code: 'el-GR', nativeName: 'Ελληνικά'),
  TmdbContentLanguage(code: 'en-US', nativeName: 'English'),
  TmdbContentLanguage(code: 'es-ES', nativeName: 'Español (España)'),
  TmdbContentLanguage(code: 'es-MX', nativeName: 'Español (México)'),
  TmdbContentLanguage(code: 'et-EE', nativeName: 'Eesti'),
  TmdbContentLanguage(code: 'fa-IR', nativeName: 'فارسی'),
  TmdbContentLanguage(code: 'fi-FI', nativeName: 'Suomi'),
  TmdbContentLanguage(code: 'fr-FR', nativeName: 'Français'),
  TmdbContentLanguage(code: 'he-IL', nativeName: 'עברית'),
  TmdbContentLanguage(code: 'hi-IN', nativeName: 'हिन्दी'),
  TmdbContentLanguage(code: 'hr-HR', nativeName: 'Hrvatski'),
  TmdbContentLanguage(code: 'hu-HU', nativeName: 'Magyar'),
  TmdbContentLanguage(code: 'id-ID', nativeName: 'Bahasa Indonesia'),
  TmdbContentLanguage(code: 'it-IT', nativeName: 'Italiano'),
  TmdbContentLanguage(code: 'ja-JP', nativeName: '日本語'),
  TmdbContentLanguage(code: 'ka-GE', nativeName: 'ქართული'),
  TmdbContentLanguage(code: 'kk-KZ', nativeName: 'Қазақша'),
  TmdbContentLanguage(code: 'ko-KR', nativeName: '한국어'),
  TmdbContentLanguage(code: 'lt-LT', nativeName: 'Lietuvių'),
  TmdbContentLanguage(code: 'lv-LV', nativeName: 'Latviešu'),
  TmdbContentLanguage(code: 'ms-MY', nativeName: 'Bahasa Melayu'),
  TmdbContentLanguage(code: 'nb-NO', nativeName: 'Norsk (Bokmål)'),
  TmdbContentLanguage(code: 'nl-NL', nativeName: 'Nederlands'),
  TmdbContentLanguage(code: 'pl-PL', nativeName: 'Polski'),
  TmdbContentLanguage(code: 'pt-BR', nativeName: 'Português (Brasil)'),
  TmdbContentLanguage(code: 'pt-PT', nativeName: 'Português (Portugal)'),
  TmdbContentLanguage(code: 'ro-RO', nativeName: 'Română'),
  TmdbContentLanguage(code: 'ru-RU', nativeName: 'Русский'),
  TmdbContentLanguage(code: 'sk-SK', nativeName: 'Slovenčina'),
  TmdbContentLanguage(code: 'sl-SI', nativeName: 'Slovenščina'),
  TmdbContentLanguage(code: 'sr-RS', nativeName: 'Српски'),
  TmdbContentLanguage(code: 'sv-SE', nativeName: 'Svenska'),
  TmdbContentLanguage(code: 'th-TH', nativeName: 'ไทย'),
  TmdbContentLanguage(code: 'tr-TR', nativeName: 'Türkçe'),
  TmdbContentLanguage(code: 'uk-UA', nativeName: 'Українська'),
  TmdbContentLanguage(code: 'vi-VN', nativeName: 'Tiếng Việt'),
  TmdbContentLanguage(code: 'zh-CN', nativeName: '简体中文'),
  TmdbContentLanguage(code: 'zh-TW', nativeName: '繁體中文'),
];

const Map<String, String> _kUiToContentLanguage = <String, String>{
  'en': 'en-US',
  'ru': 'ru-RU',
  'zh': 'zh-CN',
  'es': 'es-ES',
  'pt': 'pt-BR',
  'fr': 'fr-FR',
};

/// Default TMDB code for a UI locale; unknown locales fall back to `en-US`.
String defaultContentLanguageForUi(String uiLanguageCode) {
  return _kUiToContentLanguage[uiLanguageCode] ?? 'en-US';
}

/// Closest AniList title mode (romaji / english / native): everything
/// except English and Japanese degrades to romaji.
String anilistTitleLanguageForContent(String contentCode) {
  if (contentCode.startsWith('en-')) {
    return AnimeMangaTitleLanguage.english.id;
  }
  if (contentCode == 'ja-JP') {
    return AnimeMangaTitleLanguage.native.id;
  }
  return AnimeMangaTitleLanguage.romaji.id;
}
