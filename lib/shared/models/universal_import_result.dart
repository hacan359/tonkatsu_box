// Универсальная модель результата импорта.
//
// Используется всеми импортёрами (Steam, Trakt, Xcoll) для единообразного
// отображения результатов на ImportResultScreen.

import 'collection.dart';
import 'media_type.dart';

/// Универсальный результат импорта из любого источника.
class UniversalImportResult {
  /// Создаёт [UniversalImportResult].
  const UniversalImportResult({
    required this.sourceName,
    required this.success,
    this.collection,
    this.collectionId,
    this.importedByType = const <MediaType, int>{},
    this.wishlistedByType = const <MediaType, int>{},
    this.updatedByType = const <MediaType, int>{},
    this.untypedImported = 0,
    this.untypedUpdated = 0,
    this.skipped = 0,
    this.errors = const <String>[],
    this.fatalError,
  });

  /// Неудачный результат с фатальной ошибкой.
  const UniversalImportResult.failure({
    required this.sourceName,
    required String error,
  })  : success = false,
        collection = null,
        collectionId = null,
        importedByType = const <MediaType, int>{},
        wishlistedByType = const <MediaType, int>{},
        updatedByType = const <MediaType, int>{},
        untypedImported = 0,
        untypedUpdated = 0,
        skipped = 0,
        errors = const <String>[],
        fatalError = error;

  /// Название источника импорта ('Steam', 'Trakt', 'Collection File').
  final String sourceName;

  /// Импорт завершился успешно.
  final bool success;

  /// Коллекция, в которую был выполнен импорт.
  final Collection? collection;

  /// ID коллекции (используется когда объект Collection недоступен).
  final int? collectionId;

  /// Количество импортированных элементов по типу медиа.
  final Map<MediaType, int> importedByType;

  /// Количество добавленных в вишлист по типу медиа.
  final Map<MediaType, int> wishlistedByType;

  /// Количество обновлённых элементов по типу медиа.
  final Map<MediaType, int> updatedByType;

  /// Количество импортированных без per-type breakdown (xcoll).
  final int untypedImported;

  /// Количество обновлённых без per-type breakdown (xcoll).
  final int untypedUpdated;

  /// Количество пропущенных элементов.
  final int skipped;

  /// Ошибки по отдельным элементам.
  final List<String> errors;

  /// Фатальная ошибка (если импорт не удался).
  final String? fatalError;

  /// Общее количество импортированных элементов.
  int get totalImported => _sumValues(importedByType) + untypedImported;

  /// Общее количество добавленных в вишлист.
  int get totalWishlisted => _sumValues(wishlistedByType);

  /// Общее количество обновлённых элементов.
  int get totalUpdated => _sumValues(updatedByType) + untypedUpdated;

  /// Есть ли элементы в вишлисте.
  bool get hasWishlistItems => totalWishlisted > 0;

  /// Эффективный ID коллекции (из объекта или прямой).
  int? get effectiveCollectionId => collection?.id ?? collectionId;

  static int _sumValues(Map<MediaType, int> map) {
    int sum = 0;
    for (final int v in map.values) {
      sum += v;
    }
    return sum;
  }
}
