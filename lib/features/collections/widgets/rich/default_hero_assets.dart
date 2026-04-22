// Дефолтные hero-картинки для коллекций без собственной обложки.
//
// Файлы лежат в `assets/images/collection_hero_defaults/`. Чтобы добавить
// новую заглушку:
//   1) положить PNG/JPG в каталог (желательно 2560×1080, 21:9);
//   2) добавить имя файла в [_defaultHeroAssets] ниже.
//
// Выбор заглушки — детерминированный: одна коллекция всегда получает
// одну и ту же картинку (по `id` коллекции).

/// Имена файлов в `assets/images/collection_hero_defaults/`.
///
/// Добавляй сюда новые заглушки. Если список пустой — фолбэк выключен.
const List<String> _defaultHeroAssets = <String>[
  'hero_4.jpg',
  'hero_5.jpg',
  'hero_6.jpg',
];

/// Базовый путь к каталогу дефолтных картинок.
const String _defaultHeroDir = 'assets/images/collection_hero_defaults/';

/// Возвращает asset-путь дефолтной hero-картинки для коллекции с id
/// [collectionId] или `null`, если дефолтных картинок пока нет.
///
/// Выбор детерминированный: `collectionId % N` — та же коллекция всегда
/// получит ту же картинку.
String? defaultHeroAssetForCollection(int collectionId) {
  if (_defaultHeroAssets.isEmpty) return null;
  final int index = collectionId.abs() % _defaultHeroAssets.length;
  return '$_defaultHeroDir${_defaultHeroAssets[index]}';
}
