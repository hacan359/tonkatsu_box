import 'package:core/models/item_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/item_mark_controls.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late MockDatabaseService mockDb;
  late MockItemMarkDao mockDao;

  setUp(() {
    mockDb = MockDatabaseService();
    mockDao = MockItemMarkDao();
    when(() => mockDb.itemMarkDao).thenReturn(mockDao);
    when(() => mockDao.getMarksForItem(any()))
        .thenAnswer((_) async => <ItemMark>[]);
    when(() => mockDao.setFavorite(any(), any(), any(), any(),
        isFavorite: any(named: 'isFavorite'))).thenAnswer((_) async => null);
    when(() => mockDao.setComment(any(), any(), any(), any(), any()))
        .thenAnswer((_) async => null);
  });

  List<Override> overrides() => <Override>[
        databaseServiceProvider.overrideWithValue(mockDb),
      ];

  group('ItemMarkControls', () {
    testWidgets('renders both controls without exception', (WidgetTester tester) async {
      await tester.pumpApp(
        ItemMarkControls(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          onNotePressed: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('note-only mode hides the like button', (WidgetTester tester) async {
      await tester.pumpApp(
        ItemMarkControls(
          itemId: 1,
          unitType: kUnitSeason,
          parentNumber: 2,
          unitNumber: 0,
          showLike: false,
          onNotePressed: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('tapping the like button writes through the provider',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ItemMarkControls(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          onNotePressed: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      verify(() => mockDao.setFavorite(1, kUnitEpisode, 1, 3,
          isFavorite: true)).called(1);
    });

    testWidgets('tapping the note button fires onNotePressed',
        (WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpApp(
        ItemMarkControls(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          onNotePressed: () => pressed++,
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      await tester.tap(find.byType(IconButton).last);
      await tester.pumpAndSettle();

      expect(pressed, 1);
      verifyNever(() => mockDao.setComment(any(), any(), any(), any(), any()));
    });
  });

  group('ItemMarkNoteEditor', () {
    testWidgets('saves the entered text and calls onDone on the done button',
        (WidgetTester tester) async {
      int done = 0;
      await tester.pumpApp(
        ItemMarkNoteEditor(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          accentColor: Colors.teal,
          onDone: () => done++,
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      await tester.enterText(find.byType(TextField), 'great one');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(done, 1);
      verify(() => mockDao.setComment(1, kUnitEpisode, 1, 3, 'great one'))
          .called(1);
    });

    testWidgets('autosaves after a pause without pressing done',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ItemMarkNoteEditor(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          accentColor: Colors.teal,
          onDone: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      await tester.enterText(find.byType(TextField), 'typed');
      await tester.pump(const Duration(seconds: 2));

      verify(() => mockDao.setComment(1, kUnitEpisode, 1, 3, 'typed'))
          .called(1);
    });

    testWidgets('does not write anything on dispose when text is untouched',
        (WidgetTester tester) async {
      await tester.pumpApp(
        ItemMarkNoteEditor(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          accentColor: Colors.teal,
          onDone: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();

      // Replace the editor without touching the text — dispose must not save.
      await tester.pumpApp(
        const SizedBox.shrink(),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      verifyNever(() => mockDao.setComment(any(), any(), any(), any(), any()));
    });

    testWidgets('renders on a phone-sized viewport', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        ItemMarkNoteEditor(
          itemId: 1,
          unitType: kUnitEpisode,
          parentNumber: 1,
          unitNumber: 3,
          accentColor: Colors.teal,
          onDone: () {},
        ),
        overrides: overrides(),
        wrapInScaffold: true,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
