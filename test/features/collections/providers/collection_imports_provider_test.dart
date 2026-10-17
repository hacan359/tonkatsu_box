import 'package:core/models/collection_import.dart';
import 'package:core/models/import_source_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/providers/collection_imports_provider.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService db;
  late MockCollectionImportDao importDao;

  setUpAll(registerAllFallbacks);

  setUp(() {
    db = MockDatabaseService();
    importDao = MockCollectionImportDao();
    when(() => db.collectionImportDao).thenReturn(importDao);
    when(() => importDao.upsert(any())).thenAnswer((_) async {});
  });

  Future<void> record(
    WidgetTester tester, {
    required int? collectionId,
    Map<String, Object?> options = const <String, Object?>{},
  }) async {
    late WidgetRef capturedRef;
    await tester.pumpApp(
      Consumer(
        builder: (BuildContext _, WidgetRef ref, Widget? _) {
          capturedRef = ref;
          return const SizedBox.shrink();
        },
      ),
      overrides: <Override>[databaseServiceProvider.overrideWithValue(db)],
    );
    await recordCollectionImport(
      capturedRef,
      source: ImportSourceKind.trakt,
      collectionId: collectionId,
      options: options,
    );
  }

  group('recordCollectionImport', () {
    testWidgets('should upsert the run with its source and options', (
      WidgetTester tester,
    ) async {
      await record(
        tester,
        collectionId: 4,
        options: <String, Object?>{CollectionImportOption.importWatched: false},
      );

      final CollectionImport saved =
          verify(() => importDao.upsert(captureAny())).captured.single
              as CollectionImport;
      expect(saved.collectionId, 4);
      expect(saved.source, ImportSourceKind.trakt);
      expect(
        saved.flag(CollectionImportOption.importWatched, orElse: true),
        isFalse,
      );
    });

    testWidgets('should write nothing when the import produced no collection', (
      WidgetTester tester,
    ) async {
      await record(tester, collectionId: null);

      verifyNever(() => importDao.upsert(any()));
    });

    testWidgets('should swallow a storage failure', (
      WidgetTester tester,
    ) async {
      when(() => importDao.upsert(any())).thenThrow(Exception('locked'));

      await record(tester, collectionId: 4);

      expect(tester.takeException(), isNull);
    });
  });
}
