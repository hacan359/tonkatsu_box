/// App locale → TheTVDB 3-letter code. Portuguese is listed twice upstream
/// (`por` and `pt`), so callers must try both.
const Map<String, List<String>> tvdbLanguageCodes = <String, List<String>>{
  'en': <String>['eng'],
  'ru': <String>['rus'],
  'es': <String>['spa'],
  'fr': <String>['fra'],
  'pt': <String>['por', 'pt'],
  'zh': <String>['zho'],
};

/// Codes to try for [appLocale], English last as the universal fallback.
List<String> tvdbCodesFor(String appLocale) {
  final List<String> codes = tvdbLanguageCodes[appLocale] ?? const <String>[];
  return <String>[...codes, 'eng'];
}

/// Numeric id from either shape TheTVDB returns: `id` as an int on detail
/// records, or the prefixed `"movie-113"` / plain `tvdb_id` string on search.
int? tvdbNumericId(Map<String, dynamic> json) {
  final Object? id = json['id'];
  if (id is int) return id;
  final Object? tvdbId = json['tvdb_id'];
  if (tvdbId is int) return tvdbId;
  if (tvdbId is String) return int.tryParse(tvdbId);
  if (id is String) return int.tryParse(id.split('-').last);
  return null;
}

/// Value of [field] for the first matching language in [locale]'s code list.
///
/// Handles the `?meta=translations` shape (a list of
/// `{field, language}` objects) and the search shape (a `language → value` map).
String? tvdbTranslation(Object? translations, String field, String locale) {
  final List<String> codes = tvdbCodesFor(locale);
  if (translations is Map<String, dynamic>) {
    for (final String code in codes) {
      final Object? value = translations[code];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
  if (translations is List<dynamic>) {
    for (final String code in codes) {
      for (final dynamic entry in translations) {
        if (entry is! Map<String, dynamic>) continue;
        if (entry['language'] != code) continue;
        final Object? value = entry[field];
        if (value is String && value.isNotEmpty) return value;
      }
    }
  }
  return null;
}

/// The two containers a record can carry translations in: `?meta=translations`
/// nests them, a search hit puts them in `translations` / `overviews`.
({Object? names, Object? overviews}) tvdbTranslationContainers(
  Map<String, dynamic> json,
) {
  final Map<String, dynamic>? meta =
      json['translations'] as Map<String, dynamic>?;
  return (
    names: meta?['nameTranslations'] ?? json['translations'],
    overviews: meta?['overviewTranslations'] ?? json['overviews'],
  );
}

/// Names out of the `[{id, name, slug}]` shape used by genres and studios.
List<String>? tvdbNames(Object? entries) {
  if (entries is! List<dynamic>) return null;
  final List<String> names = <String>[
    for (final dynamic e in entries)
      if (e is Map<String, dynamic> && e['name'] is String) e['name'] as String
      else if (e is String) e,
  ];
  return names.isEmpty ? null : names;
}

/// Id of [sourceName] in a `remote_ids` / `remoteIds` list. Matching is by name
/// because the numeric `type` differs per record kind (TMDB is 10 for movies,
/// 12 for series).
String? tvdbRemoteId(Object? remoteIds, String sourceName) {
  if (remoteIds is! List<dynamic>) return null;
  for (final dynamic entry in remoteIds) {
    if (entry is! Map<String, dynamic>) continue;
    if (entry['sourceName'] != sourceName) continue;
    final Object? id = entry['id'];
    if (id is String && id.isNotEmpty) return id;
  }
  return null;
}

/// `/search` and `/extended` return absolute artwork URLs, `/filter` returns a
/// bare path — this makes both usable.
String? tvdbImageUrl(Object? url) {
  if (url is! String || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  return 'https://artworks.thetvdb.com${url.startsWith('/') ? '' : '/'}$url';
}

/// Thumbnail variant of an artworks.thetvdb.com URL (`foo.jpg` → `foo_t.jpg`).
String? tvdbThumbUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final int dot = url.lastIndexOf('.');
  if (dot <= url.lastIndexOf('/')) return url;
  return '${url.substring(0, dot)}_t${url.substring(dot)}';
}

/// Public record URL. TheTVDB's free tier requires a working link back, and
/// `/movies/<numeric id>` 404s — the legacy query form is the slugless fallback.
String tvdbRecordUrl(String tab, Object? slug, int id) {
  if (slug is String && slug.isNotEmpty) {
    return 'https://thetvdb.com/$tab/$slug';
  }
  return 'https://thetvdb.com/?tab=$tab&id=$id';
}

/// Leading year of `2010`, `2010-07-08` and the empty-string case alike.
int? tvdbYear(Object? value) {
  if (value is int) return value;
  if (value is! String || value.length < 4) return null;
  return int.tryParse(value.substring(0, 4));
}
