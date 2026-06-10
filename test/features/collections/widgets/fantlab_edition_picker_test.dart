import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/fantlab_api.dart';
import 'package:tonkatsu_box/features/collections/widgets/fantlab_edition_picker.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/models/book.dart';
import 'package:tonkatsu_box/shared/models/data_source.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(registerAllFallbacks);

  group('applyFantlabEdition', () {
    test('overlays cover and metadata while keeping work identity', () {
      final Book book = createTestBook(
        id: '3104',
        source: DataSource.fantlab,
        nativeId: '3104',
        title: 'Solaris',
      );
      const FantlabEdition edition = FantlabEdition(
        editionId: 24724,
        name: 'Солярис',
        hasCover: true,
        year: 1992,
        langCode: 'ru',
        publisher: 'Мир',
        pages: 480,
        isbn: '9785699120148',
      );

      final Book result = applyFantlabEdition(book, edition);

      expect(result.coverUrl, 'https://fantlab.ru/images/editions/big/24724');
      expect(result.publishYear, 1992);
      expect(result.pageCount, 480);
      expect(result.isbn13, '9785699120148');
      expect(result.publishers, <String>['Мир']);
      expect(result.languages, <String>['ru']);
      // Identity untouched.
      expect(result.id, '3104');
      expect(result.nativeId, '3104');
      expect(result.source, DataSource.fantlab);
    });

    test('keeps existing book fields the edition does not provide', () {
      final Book book = createTestBook(
        id: '3104',
        source: DataSource.fantlab,
        publishYear: 2000,
        pageCount: 100,
      );
      const FantlabEdition edition =
          FantlabEdition(editionId: 5, name: 'x', hasCover: false);

      final Book result = applyFantlabEdition(book, edition);

      expect(result.publishYear, 2000);
      expect(result.pageCount, 100);
      expect(result.coverUrl, 'https://fantlab.ru/images/editions/big/5');
    });
  });

  group('editionIdFromCoverUrl', () {
    test('extracts the edition id from a cover URL', () {
      expect(
        editionIdFromCoverUrl('https://fantlab.ru/images/editions/big/24724'),
        24724,
      );
      expect(
        editionIdFromCoverUrl(
            'https://fantlab.ru/images/editions/small/7?r=1'),
        7,
      );
    });

    test('returns null for a non-edition URL', () {
      expect(editionIdFromCoverUrl(null), isNull);
      expect(editionIdFromCoverUrl('https://example.com/x.jpg'), isNull);
    });
  });

  group('showFantlabEditionPicker', () {
    late MockFantlabApi mockApi;

    setUp(() => mockApi = MockFantlabApi());

    Widget host(String workId) {
      FantlabEdition? picked;
      return ProviderScope(
        overrides: <Override>[
          fantlabApiProvider.overrideWithValue(mockApi),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (BuildContext ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    picked = await showFantlabEditionPicker(ctx,
                        workId: workId);
                    _lastPicked = picked;
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('lists editions and returns the tapped one',
        (WidgetTester tester) async {
      when(() => mockApi.getEditions('3104')).thenAnswer(
        (_) async => <FantlabEditionBlock>[
          const FantlabEditionBlock(
            title: 'Издания',
            editions: <FantlabEdition>[
              FantlabEdition(
                editionId: 1,
                name: 'A',
                hasCover: false,
                year: 1973,
                publisher: 'Мир',
                langCode: 'ru',
              ),
              FantlabEdition(
                editionId: 2,
                name: 'B',
                hasCover: false,
                year: 1983,
                langCode: 'en',
              ),
            ],
          ),
        ],
      );

      _lastPicked = null;
      await tester.pumpWidget(host('3104'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Data-driven captions render.
      expect(find.textContaining('1973'), findsOneWidget);
      expect(find.textContaining('Мир'), findsOneWidget);

      await tester.tap(find.textContaining('1983'));
      await tester.pumpAndSettle();

      expect(_lastPicked, isNotNull);
      expect(_lastPicked!.editionId, 2);
    });

    testWidgets('renders no edition cards when there are none',
        (WidgetTester tester) async {
      when(() => mockApi.getEditions('999'))
          .thenAnswer((_) async => const <FantlabEditionBlock>[]);

      await tester.pumpWidget(host('999'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('·'), findsNothing);
    });
  });

  group('FantlabEditionsSection', () {
    late MockFantlabApi mockApi;

    setUp(() => mockApi = MockFantlabApi());

    Widget host(
      String workId,
      void Function(FantlabEdition) onSelected, {
      int? selectedId,
    }) {
      return ProviderScope(
        overrides: <Override>[
          fantlabApiProvider.overrideWithValue(mockApi),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FantlabEditionsSection(
                workId: workId,
                selectedEditionId: selectedId,
                onSelected: onSelected,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders editions and reports the tapped one',
        (WidgetTester tester) async {
      when(() => mockApi.getEditions('7104')).thenAnswer(
        (_) async => <FantlabEditionBlock>[
          const FantlabEditionBlock(
            title: 'Издания',
            editions: <FantlabEdition>[
              FantlabEdition(
                editionId: 11,
                name: 'A',
                hasCover: false,
                year: 1973,
                publisher: 'Мир',
                langCode: 'ru',
              ),
            ],
          ),
        ],
      );

      FantlabEdition? tapped;
      await tester.pumpWidget(host('7104', (FantlabEdition e) => tapped = e));
      await tester.pumpAndSettle();

      expect(find.textContaining('1973'), findsOneWidget);

      await tester.tap(find.textContaining('1973'));
      await tester.pumpAndSettle();

      expect(tapped?.editionId, 11);
    });

    testWidgets('hides when the work has no editions',
        (WidgetTester tester) async {
      when(() => mockApi.getEditions('7999'))
          .thenAnswer((_) async => const <FantlabEditionBlock>[]);

      await tester.pumpWidget(host('7999', (_) {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('·'), findsNothing);
    });
  });
}

/// Captured outside the widget tree so the async picker result survives the
/// button's closure.
FantlabEdition? _lastPicked;
