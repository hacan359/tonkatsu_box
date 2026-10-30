import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/settings/widgets/remembered_import_collection.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService db;
  late MockCollectionImportDao importDao;

  setUpAll(registerAllFallbacks);

  setUp(() {
    db = MockDatabaseService();
    importDao = MockCollectionImportDao();
    when(() => db.collectionImportDao).thenReturn(importDao);
  });

  Future<int?> pump(WidgetTester tester, {int? initialCollectionId}) async {
    int? received;
    await tester.pumpApp(
      RememberedImportCollection(
        source: ImportSourceKind.steam,
        initialCollectionId: initialCollectionId,
        builder: (int? collectionId) {
          received = collectionId;
          return Text('built:$collectionId');
        },
      ),
      overrides: <Override>[databaseServiceProvider.overrideWithValue(db)],
    );
    return received;
  }

  group('RememberedImportCollection', () {
    testWidgets('should pass the given id through without touching the DAO', (
      WidgetTester tester,
    ) async {
      final int? received = await pump(tester, initialCollectionId: 5);

      expect(received, 5);
      verifyNever(() => importDao.getLatestForSource(any()));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should resolve the last collection of the source when none given',
      (WidgetTester tester) async {
        when(
          () => importDao.getLatestForSource(ImportSourceKind.steam),
        ).thenAnswer(
          (_) async => CollectionImport(
            collectionId: 9,
            source: ImportSourceKind.steam,
            lastRunAt: DateTime.now(),
          ),
        );

        final int? received = await pump(tester);

        expect(received, 9);
        expect(find.text('built:9'), findsOneWidget);
      },
    );

    testWidgets('should build with null when the source never ran', (
      WidgetTester tester,
    ) async {
      when(
        () => importDao.getLatestForSource(any()),
      ).thenAnswer((_) async => null);

      final int? received = await pump(tester);

      expect(received, isNull);
      expect(find.text('built:null'), findsOneWidget);
    });

    testWidgets('should still build the form when the lookup fails', (
      WidgetTester tester,
    ) async {
      when(
        () => importDao.getLatestForSource(any()),
      ).thenThrow(Exception('db down'));

      final int? received = await pump(tester);

      expect(received, isNull);
      expect(tester.takeException(), isNull);
    });
  });
}
