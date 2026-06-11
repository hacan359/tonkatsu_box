// Default hero images for collections without a custom cover.

/// To add a placeholder: drop a PNG/JPG (ideally 2560×1080, 21:9) into
/// `assets/images/collection_hero_defaults/` and list it here.
/// An empty list disables the fallback.
const List<String> _defaultHeroAssets = <String>[
  'hero_4.jpg',
  'hero_5.jpg',
  'hero_6.jpg',
];

const String _defaultHeroDir = 'assets/images/collection_hero_defaults/';

/// Returns `null` when no default images are bundled.
///
/// Selection is deterministic (`collectionId % N`): the same collection
/// always gets the same image.
String? defaultHeroAssetForCollection(int collectionId) {
  if (_defaultHeroAssets.isEmpty) return null;
  final int index = collectionId.abs() % _defaultHeroAssets.length;
  return '$_defaultHeroDir${_defaultHeroAssets[index]}';
}
