import 'package:core/models/book.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/api/hardcover_api.dart';
import 'package:tonkatsu_box/features/collections/widgets/hardcover_edition_picker.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

Book _hardcoverBook({
  String id = '465829',
  String title = 'World of Warcraft: Перед бурей',
  String? originalTitle,
  String? coverUrl,
  String? externalUrl,
}) {
  return createTestBook(
    id: id,
    source: DataSource.hardcover,
    nativeId: id,
    title: title,
    originalTitle: originalTitle,
    coverUrl: coverUrl,
    externalUrl: externalUrl ?? 'https://hardcover.app/id/book/$id',
  );
}

const HardcoverEdition _enEdition = HardcoverEdition(
  id: 30383507,
  bookId: 465829,
  title: 'World of Warcraft: Before the Storm',
  coverUrl: 'https://assets.hardcover.app/external_data/59489650/cover.jpeg',
  languageCode: 'en',
  publisher: 'Del Rey',
  pages: 304,
  isbn10: '0399594094',
  isbn13: '9780399594090',
  releaseYear: 2018,
  usersCount: 10,
);

/// Captured outside the widget tree so the async picker result survives the
/// button's closure.
HardcoverEdition? _lastPicked;

void main() {
  setUpAll(registerAllFallbacks);

  group('applyHardcoverEdition', () {
    test('overlays edition fields and swaps the localized title', () {
      final Book book = _hardcoverBook();

      final Book result = applyHardcoverEdition(book, _enEdition);

      expect(result.title, 'World of Warcraft: Before the Storm');
      expect(result.originalTitle, 'World of Warcraft: Перед бурей');
      expect(result.coverUrl, _enEdition.coverUrl);
      expect(result.publishYear, 2018);
      expect(result.pageCount, 304);
      expect(result.isbn10, '0399594094');
      expect(result.isbn13, '9780399594090');
      expect(result.languages, <String>['en']);
      expect(result.publishers, <String>['Del Rey']);
      // Identity untouched.
      expect(result.id, '465829');
      expect(result.nativeId, '465829');
      expect(result.source, DataSource.hardcover);
    });

    test('records the edition id as an external URL fragment', () {
      final Book result = applyHardcoverEdition(_hardcoverBook(), _enEdition);

      expect(
        result.externalUrl,
        'https://hardcover.app/id/book/465829#edition-30383507',
      );
    });

    test('replaces a previous edition fragment instead of stacking', () {
      final Book book = _hardcoverBook(
        externalUrl: 'https://hardcover.app/id/book/465829#edition-111',
      );

      final Book result = applyHardcoverEdition(book, _enEdition);

      expect(
        result.externalUrl,
        'https://hardcover.app/id/book/465829#edition-30383507',
      );
    });

    test('keeps an existing original title', () {
      final Book book = _hardcoverBook(originalTitle: 'Original');

      final Book result = applyHardcoverEdition(book, _enEdition);

      expect(result.originalTitle, 'Original');
    });

    test('keeps book fields the edition does not provide', () {
      final Book book = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/external_data/1/book.jpg',
      );
      const HardcoverEdition sparse = HardcoverEdition(
        id: 7,
        bookId: 465829,
        title: '',
      );

      final Book result = applyHardcoverEdition(book, sparse);

      expect(result.title, book.title);
      expect(result.originalTitle, isNull);
      expect(result.coverUrl, book.coverUrl);
      expect(result.publishYear, book.publishYear);
    });
  });

  group('hardcoverEditionIdFromExternalUrl', () {
    test('extracts the id from the edition fragment', () {
      expect(
        hardcoverEditionIdFromExternalUrl(
            'https://hardcover.app/id/book/465829#edition-30383507'),
        30383507,
      );
    });

    test('returns null without a fragment', () {
      expect(hardcoverEditionIdFromExternalUrl(null), isNull);
      expect(
        hardcoverEditionIdFromExternalUrl(
            'https://hardcover.app/id/book/465829'),
        isNull,
      );
    });
  });

  group('hardcoverEditionIdFromCoverUrl', () {
    test('extracts the id from both edition URL shapes', () {
      expect(
        hardcoverEditionIdFromCoverUrl(
            'https://assets.hardcover.app/editions/30426415/cover.jpg'),
        30426415,
      );
      expect(
        hardcoverEditionIdFromCoverUrl(
            'https://assets.hardcover.app/edition/30400610/cover.jpg'),
        30400610,
      );
    });

    test('returns null for external_data and foreign URLs', () {
      expect(hardcoverEditionIdFromCoverUrl(null), isNull);
      expect(
        hardcoverEditionIdFromCoverUrl(
            'https://assets.hardcover.app/external_data/59489650/x.jpeg'),
        isNull,
      );
      expect(
        hardcoverEditionIdFromCoverUrl('https://example.com/editions/5/x.jpg'),
        isNull,
      );
    });
  });

  group('reapplyHardcoverEdition', () {
    late MockHardcoverApi api;

    setUp(() => api = MockHardcoverApi());

    test('returns fresh as-is when nothing was picked', () async {
      final Book cached = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/external_data/1/x.jpg',
      );
      final Book fresh = _hardcoverBook();

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result, same(fresh));
      verifyNever(() => api.getEdition(any()));
    });

    test('treats a cover matching the fresh default as no pick', () async {
      final Book cached = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/editions/30426415/x.jpg',
      );
      final Book fresh = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/editions/30426415/x.jpg',
      );

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result, same(fresh));
      verifyNever(() => api.getEdition(any()));
    });

    test('re-applies an explicitly picked edition from the URL fragment',
        () async {
      when(() => api.getEdition(30383507))
          .thenAnswer((_) async => _enEdition);
      final Book cached = _hardcoverBook(
        externalUrl: 'https://hardcover.app/id/book/465829#edition-30383507',
        coverUrl: 'https://assets.hardcover.app/external_data/59489650/x.jpeg',
      );
      final Book fresh = _hardcoverBook();

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result.title, 'World of Warcraft: Before the Storm');
      expect(result.languages, <String>['en']);
      expect(
        result.externalUrl,
        'https://hardcover.app/id/book/465829#edition-30383507',
      );
    });

    test('re-applies a cover-derived pick that differs from the default',
        () async {
      when(() => api.getEdition(30383507))
          .thenAnswer((_) async => _enEdition);
      final Book cached = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/editions/30383507/x.jpg',
      );
      final Book fresh = _hardcoverBook(
        coverUrl: 'https://assets.hardcover.app/editions/32753857/x.jpg',
      );

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result.title, 'World of Warcraft: Before the Storm');
    });

    test('falls back to fresh when the edition no longer exists', () async {
      when(() => api.getEdition(30383507)).thenAnswer((_) async => null);
      final Book cached = _hardcoverBook(
        externalUrl: 'https://hardcover.app/id/book/465829#edition-30383507',
      );
      final Book fresh = _hardcoverBook();

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result, same(fresh));
    });

    test('falls back to fresh when the edition belongs to another book',
        () async {
      const HardcoverEdition foreign = HardcoverEdition(
        id: 30383507,
        bookId: 999,
        title: 'Other',
      );
      when(() => api.getEdition(30383507))
          .thenAnswer((_) async => foreign);
      final Book cached = _hardcoverBook(
        externalUrl: 'https://hardcover.app/id/book/465829#edition-30383507',
      );
      final Book fresh = _hardcoverBook();

      final Book result =
          await reapplyHardcoverEdition(api, cached: cached, fresh: fresh);

      expect(result, same(fresh));
    });
  });

  group('showHardcoverEditionPicker', () {
    late MockHardcoverApi api;

    setUp(() => api = MockHardcoverApi());

    Widget host(String bookId, {int? currentId}) {
      return ProviderScope(
        overrides: <Override>[
          hardcoverApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (BuildContext ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    _lastPicked = await showHardcoverEditionPicker(
                      ctx,
                      bookId: bookId,
                      currentEditionId: currentId,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('groups editions by language and returns the tapped one',
        (WidgetTester tester) async {
      when(() => api.getEditions('200001')).thenAnswer(
        (_) async => const <HardcoverEdition>[
          HardcoverEdition(
            id: 1,
            bookId: 200001,
            title: 'A',
            releaseYear: 1973,
            publisher: 'Del Rey',
            languageCode: 'en',
          ),
          HardcoverEdition(
            id: 2,
            bookId: 200001,
            title: 'B',
            releaseYear: 1983,
            publisher: 'АСТ',
            languageCode: 'ru',
          ),
          HardcoverEdition(
            id: 3,
            bookId: 200001,
            title: 'C',
            releaseYear: 1993,
          ),
        ],
      );

      _lastPicked = null;
      await tester.pumpWidget(host('200001'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Language group headers with counts; the language-less group last.
      expect(find.text('EN (1)'), findsOneWidget);
      expect(find.text('RU (1)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('— (1)'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('— (1)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.textContaining('1983'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.textContaining('1983'));
      await tester.pumpAndSettle();

      expect(_lastPicked, isNotNull);
      expect(_lastPicked!.id, 2);
    });

    testWidgets('resolves to null when dismissed without a pick',
        (WidgetTester tester) async {
      when(() => api.getEditions('200002')).thenAnswer(
        (_) async => const <HardcoverEdition>[
          HardcoverEdition(id: 1, bookId: 200002, title: 'A'),
        ],
      );

      _lastPicked = const HardcoverEdition(id: 99, bookId: 0, title: 'x');
      await tester.pumpWidget(host('200002'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(_lastPicked, isNull);
    });

    testWidgets('shows the empty message when there are no editions',
        (WidgetTester tester) async {
      when(() => api.getEditions('200003'))
          .thenAnswer((_) async => const <HardcoverEdition>[]);

      await tester.pumpWidget(host('200003'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('·'), findsNothing);
    });
  });

  group('HardcoverEditionsSection', () {
    late MockHardcoverApi api;

    setUp(() => api = MockHardcoverApi());

    Widget host(
      String bookId,
      void Function(HardcoverEdition) onSelected, {
      int? selectedId,
    }) {
      return ProviderScope(
        overrides: <Override>[
          hardcoverApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HardcoverEditionsSection(
                bookId: bookId,
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
      when(() => api.getEditions('100001')).thenAnswer(
        (_) async => const <HardcoverEdition>[
          HardcoverEdition(
            id: 1,
            bookId: 100001,
            title: 'A',
            releaseYear: 1973,
            publisher: 'Del Rey',
            languageCode: 'en',
          ),
        ],
      );

      HardcoverEdition? tapped;
      await tester
          .pumpWidget(host('100001', (HardcoverEdition e) => tapped = e));
      await tester.pumpAndSettle();

      expect(find.textContaining('1973'), findsOneWidget);

      await tester.tap(find.textContaining('1973'));
      await tester.pumpAndSettle();

      expect(tapped?.id, 1);
    });

    testWidgets('filters the strip by the tapped language chip',
        (WidgetTester tester) async {
      when(() => api.getEditions('100002')).thenAnswer(
        (_) async => const <HardcoverEdition>[
          HardcoverEdition(
            id: 1,
            bookId: 100002,
            title: 'A',
            releaseYear: 1973,
            languageCode: 'en',
          ),
          HardcoverEdition(
            id: 2,
            bookId: 100002,
            title: 'B',
            releaseYear: 1983,
            languageCode: 'ru',
          ),
        ],
      );

      await tester.pumpWidget(host('100002', (_) {}));
      await tester.pumpAndSettle();

      // Both editions visible before filtering.
      expect(find.textContaining('1973'), findsOneWidget);
      expect(find.textContaining('1983'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'RU'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1973'), findsNothing);
      expect(find.textContaining('1983'), findsOneWidget);
    });

    testWidgets('shows no language chips for a single language',
        (WidgetTester tester) async {
      when(() => api.getEditions('100003')).thenAnswer(
        (_) async => const <HardcoverEdition>[
          HardcoverEdition(
            id: 1,
            bookId: 100003,
            title: 'A',
            releaseYear: 1973,
            languageCode: 'en',
          ),
        ],
      );

      await tester.pumpWidget(host('100003', (_) {}));
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNothing);
    });

    testWidgets('hides when the book has no editions',
        (WidgetTester tester) async {
      when(() => api.getEditions('100004'))
          .thenAnswer((_) async => const <HardcoverEdition>[]);

      await tester.pumpWidget(host('100004', (_) {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('·'), findsNothing);
    });
  });
}
