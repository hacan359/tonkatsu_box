// Информация о принадлежности элемента к коллекции.

/// Данные о нахождении элемента в коллекции.
///
/// Используется для маркировки результатов поиска и удаления элементов.
/// Если [collectionId] == null, элемент является «без коллекции».
class CollectedItemInfo {
  /// Создаёт [CollectedItemInfo].
  const CollectedItemInfo({
    required this.recordId,
    required this.collectionId,
    required this.collectionName,
  });

  /// ID записи в таблице collection_items.
  final int recordId;

  /// ID коллекции (null для элементов без коллекции).
  final int? collectionId;

  /// Название коллекции (null для элементов без коллекции).
  final String? collectionName;

  @override
  String toString() =>
      'CollectedItemInfo(recordId: $recordId, '
      'collectionId: $collectionId, '
      'collectionName: $collectionName)';
}
