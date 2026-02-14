// Умный тест-сторож: автоматически обнаруживает забытые поля в экспорте.

import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/models/canvas_connection.dart';
import 'package:xerabora/shared/models/canvas_item.dart';
import 'package:xerabora/shared/models/canvas_viewport.dart';
import 'package:xerabora/shared/models/collection.dart';
import 'package:xerabora/shared/models/collection_item.dart';
import 'package:xerabora/shared/models/exportable.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  // -- Тестовые данные с заполненными полями --

  final DateTime testDate = DateTime(2025, 1, 15, 12, 0);

  final CollectionItem testCollectionItem = CollectionItem(
    id: 1,
    collectionId: 10,
    mediaType: MediaType.tvShow,
    externalId: 1399,
    platformId: 48,
    currentSeason: 3,
    currentEpisode: 5,
    status: ItemStatus.inProgress,
    authorComment: 'Отличный сериал',
    userComment: 'Мои заметки',
    addedAt: testDate,
  );

  final Collection testCollection = Collection(
    id: 1,
    name: 'Test Collection',
    author: 'Test Author',
    type: CollectionType.own,
    createdAt: testDate,
    originalSnapshot: '{}',
    forkedFromAuthor: 'Other Author',
    forkedFromName: 'Other Collection',
  );

  final CanvasItem testCanvasItem = CanvasItem(
    id: 5,
    collectionId: 10,
    collectionItemId: 42,
    itemType: CanvasItemType.game,
    itemRefId: 100,
    x: 50.0,
    y: 100.0,
    width: 160.0,
    height: 220.0,
    zIndex: 2,
    data: const <String, dynamic>{'content': 'test'},
    createdAt: testDate,
  );

  final CanvasConnection testCanvasConnection = CanvasConnection(
    id: 3,
    collectionId: 10,
    collectionItemId: 42,
    fromItemId: 100,
    toItemId: 200,
    label: 'test label',
    color: '#0000FF',
    style: ConnectionStyle.dashed,
    createdAt: testDate,
  );

  const CanvasViewport testCanvasViewport = CanvasViewport(
    collectionId: 10,
    scale: 1.5,
    offsetX: -100.0,
    offsetY: -200.0,
  );

  /// Проверяет Exportable контракт для модели.
  ///
  /// 6 тестов:
  /// 1. Полнота покрытия — каждое поле toDb() в export или internal
  /// 2. internal и export не пересекаются
  /// 3. mapping ссылается на реальные toDb() ключи
  /// 4. Round-trip — toExport → fromExport → toExport
  /// 5. Forward compat — неизвестные поля игнорируются
  /// 6. Backward compat — defaults для отсутствующих полей
  void testExportableContract({
    required String modelName,
    required Exportable instance,
    required Exportable Function(Map<String, dynamic> json) fromExport,
    required Map<String, dynamic> minimalExportJson,
  }) {
    group(modelName, () {
      test('каждое поле toDb() либо экспортируется, либо в internalDbFields',
          () {
        final Set<String> dbKeys = instance.toDb().keys.toSet();
        final Map<String, String> mapping = instance.dbToExportKeyMapping;
        final Set<String> exportKeys = instance.toExport().keys.toSet();
        final Set<String> internal = instance.internalDbFields;

        for (final String dbKey in dbKeys) {
          final String exportKey = mapping[dbKey] ?? dbKey;
          final bool isInternal = internal.contains(dbKey);
          final bool isExported = exportKeys.contains(exportKey);

          expect(
            isInternal || isExported,
            isTrue,
            reason: 'Поле "$dbKey" из toDb() не найдено ни в toExport() '
                '(как "$exportKey"), ни в internalDbFields. '
                'Добавьте его в одно из этих мест.',
          );
        }
      });

      test('internalDbFields не содержат экспортируемых полей', () {
        final Map<String, String> mapping = instance.dbToExportKeyMapping;
        final Set<String> exportKeys = instance.toExport().keys.toSet();
        final Set<String> internal = instance.internalDbFields;

        for (final String internalKey in internal) {
          final String exportKey = mapping[internalKey] ?? internalKey;
          expect(
            exportKeys.contains(exportKey),
            isFalse,
            reason: 'Поле "$internalKey" одновременно в internalDbFields '
                'и в toExport() (как "$exportKey"). '
                'Уберите его из одного места.',
          );
        }
      });

      test('dbToExportKeyMapping ссылается только на реальные toDb() ключи',
          () {
        final Set<String> dbKeys = instance.toDb().keys.toSet();
        final Map<String, String> mapping = instance.dbToExportKeyMapping;

        for (final String mappingKey in mapping.keys) {
          expect(
            dbKeys.contains(mappingKey),
            isTrue,
            reason: 'Ключ "$mappingKey" в dbToExportKeyMapping '
                'не найден в toDb(). Удалите устаревший маппинг.',
          );
        }
      });

      test('toExport() -> fromExport() -> toExport() сохраняет все данные',
          () {
        final Map<String, dynamic> exported = instance.toExport();
        final Exportable restored = fromExport(exported);
        final Map<String, dynamic> reExported = restored.toExport();

        expect(reExported, equals(exported));
      });

      test('fromExport() игнорирует неизвестные поля без ошибок', () {
        final Map<String, dynamic> exportWithExtras =
            Map<String, dynamic>.from(instance.toExport());
        exportWithExtras['future_field_123'] = 'some value';
        exportWithExtras['another_new_field'] = 42;

        // Не должен кидать исключение.
        final Exportable restored = fromExport(exportWithExtras);
        expect(restored.toExport(), isNotEmpty);
      });

      test('fromExport() использует defaults для отсутствующих полей', () {
        // Не должен кидать исключение на минимальном JSON.
        final Exportable restored = fromExport(minimalExportJson);
        expect(restored.toExport(), isNotEmpty);
      });
    });
  }

  group('Export Coverage (тест-сторож)', () {
    testExportableContract(
      modelName: 'CollectionItem',
      instance: testCollectionItem,
      fromExport: (Map<String, dynamic> json) =>
          CollectionItem.fromExport(json),
      minimalExportJson: const <String, dynamic>{
        'media_type': 'game',
        'external_id': 1,
      },
    );

    testExportableContract(
      modelName: 'Collection',
      instance: testCollection,
      fromExport: (Map<String, dynamic> json) => Collection.fromExport(json),
      minimalExportJson: <String, dynamic>{
        'name': 'Test',
        'author': 'Author',
        'created': DateTime.now().toIso8601String(),
      },
    );

    testExportableContract(
      modelName: 'CanvasItem',
      instance: testCanvasItem,
      fromExport: (Map<String, dynamic> json) =>
          CanvasItem.fromExport(json, collectionId: 10),
      minimalExportJson: const <String, dynamic>{
        'x': 0,
        'y': 0,
      },
    );

    testExportableContract(
      modelName: 'CanvasConnection',
      instance: testCanvasConnection,
      fromExport: (Map<String, dynamic> json) =>
          CanvasConnection.fromExport(json, collectionId: 10),
      minimalExportJson: const <String, dynamic>{
        'from_item_id': 1,
        'to_item_id': 2,
      },
    );

    testExportableContract(
      modelName: 'CanvasViewport',
      instance: testCanvasViewport,
      fromExport: (Map<String, dynamic> json) =>
          CanvasViewport.fromExport(json, collectionId: 10),
      minimalExportJson: const <String, dynamic>{},
    );
  });
}
