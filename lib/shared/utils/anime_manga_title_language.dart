enum AnimeMangaTitleLanguage {
  romaji('romaji'),
  english('english'),
  native('native');

  const AnimeMangaTitleLanguage(this.id);

  final String id;

  static AnimeMangaTitleLanguage fromId(String? id) {
    for (final AnimeMangaTitleLanguage v in AnimeMangaTitleLanguage.values) {
      if (v.id == id) return v;
    }
    return AnimeMangaTitleLanguage.romaji;
  }
}

/// Picks the first non-empty title in fallback order based on [lang].
/// Romaji acts as the universal fallback because AniList always returns it.
String? pickAnimeMangaTitle({
  required String lang,
  required String? romaji,
  required String? english,
  required String? native,
}) {
  String? primary;
  String? secondary;
  String? tertiary;
  switch (AnimeMangaTitleLanguage.fromId(lang)) {
    case AnimeMangaTitleLanguage.english:
      primary = english;
      secondary = romaji;
      tertiary = native;
    case AnimeMangaTitleLanguage.native:
      primary = native;
      secondary = romaji;
      tertiary = english;
    case AnimeMangaTitleLanguage.romaji:
      primary = romaji;
      secondary = english;
      tertiary = native;
  }
  if (primary != null && primary.isNotEmpty) return primary;
  if (secondary != null && secondary.isNotEmpty) return secondary;
  if (tertiary != null && tertiary.isNotEmpty) return tertiary;
  return null;
}
