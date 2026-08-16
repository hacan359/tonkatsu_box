/// To add a placeholder: drop a PNG/JPG (ideally 2560×1080, 21:9) into
/// `assets/images/collection_hero_defaults/`; an empty list disables it.
const List<String> _defaultHeroAssets = <String>[
  'hero_4.jpg',
  'hero_5.jpg',
  'hero_6.jpg',
];

const String _defaultHeroDir = 'assets/images/collection_hero_defaults/';

/// Deterministic (`collectionId % N`) so a collection keeps its image;
/// returns `null` when no default images are bundled.
String? defaultHeroAssetForCollection(int collectionId) {
  if (_defaultHeroAssets.isEmpty) return null;
  final int index = collectionId.abs() % _defaultHeroAssets.length;
  return '$_defaultHeroDir${_defaultHeroAssets[index]}';
}
