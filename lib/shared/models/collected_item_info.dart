// Информация о принадлежности элемента к коллекции.

/// Данные о нахождении элемента в коллекции.
///
/// Используется для маркировки результатов поиска и удаления элементов.
class CollectedItemInfo {
  /// Создаёт [CollectedItemInfo].
  const CollectedItemInfo({
    required this.recordId,
    required this.collectionId,
    required this.collectionName,
  });

  /// ID записи в таблице (collection_games или collection_items).
  final int recordId;

  /// ID коллекции.
  final int collectionId;

  /// Название коллекции.
  final String collectionName;
}
