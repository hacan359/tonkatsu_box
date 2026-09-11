final RegExp _isoRegion = RegExp(r'^[A-Z]{2}$');

/// `ru-RU` → `RU`. A bare language tag or a script subtag (`zh-Hans`) yields
/// null so the request goes out without a region rather than a bad one.
String? tmdbRegionFromLanguage(String language) {
  final int dash = language.lastIndexOf('-');
  if (dash < 0) return null;
  final String region = language.substring(dash + 1).toUpperCase();
  return _isoRegion.hasMatch(region) ? region : null;
}
