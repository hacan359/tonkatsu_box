import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tonkatsu_box/core/database/database_service.dart';
import 'package:tonkatsu_box/features/collections/widgets/create_custom_item_dialog.dart';
import 'package:tonkatsu_box/shared/models/custom_media.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';
import 'package:tonkatsu_box/shared/models/platform.dart';

import '../../../helpers/test_helpers.dart';

CustomMedia _media({MediaType? displayType}) => CustomMedia(
      id: 1,
      title: 'My Item',
      displayType: displayType,
      cachedAt: 1700000000,
    );

CustomItemData? _returned;

Future<void> _openEdit(
  WidgetTester tester, {
  required CustomMedia existing,
}) async {
  _returned = null;
  await tester.pumpApp(
    Builder(
      builder: (BuildContext ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              _returned = await CreateCustomItemDialog.edit(ctx, existing);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

DatabaseService _mockDb() {
  final MockDatabaseService db = MockDatabaseService();
  final MockGameDao gameDao = MockGameDao();
  final MockMovieDao movieDao = MockMovieDao();
  when(() => db.gameDao).thenReturn(gameDao);
  when(() => db.movieDao).thenReturn(movieDao);
  when(gameDao.getAllPlatforms).thenAnswer((_) async => <Platform>[]);
  when(gameDao.getIgdbGenres)
      .thenAnswer((_) async => <Map<String, dynamic>>[]);
  when(() => movieDao.getTmdbGenreMap(any()))
      .thenAnswer((_) async => <String, String>{});
  return db;
}

Future<void> _openCreate(WidgetTester tester) async {
  _returned = null;
  await tester.pumpApp(
    Builder(
      builder: (BuildContext ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              _returned = await CreateCustomItemDialog.show(ctx);
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
    overrides: <Override>[
      databaseServiceProvider.overrideWithValue(_mockDb()),
    ],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

const Key _noteKey = ValueKey<String>('customItemNoteField');
const Key _tagsKey = ValueKey<String>('customItemTagsField');

/// Scrolls the form's ListView until [finder] is built and visible.
/// TextFields carry their own Scrollables, so the target must be explicit.
Future<void> _scrollTo(WidgetTester tester, Finder finder) {
  return tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

// Chip order is custom first, then MediaType.values order, so movie is at
// index 2 (custom, game, movie, ...).
const int _movieChipIndex = 2;

void main() {
  setUpAll(registerAllFallbacks);

  group('CreateCustomItemDialog create mode', () {
    testWidgets('shows the note and tags fields',
        (WidgetTester tester) async {
      await _openCreate(tester);
      // The fields sit at the bottom of a lazy ListView.
      await _scrollTo(tester, find.byKey(_noteKey));
      expect(find.byKey(_noteKey), findsOneWidget);
      await _scrollTo(tester, find.byKey(_tagsKey));
      expect(find.byKey(_tagsKey), findsOneWidget);
    });

    testWidgets('Create returns the note and parsed tags',
        (WidgetTester tester) async {
      await _openCreate(tester);

      await tester.enterText(find.byType(TextField).first, 'My Card');
      await _scrollTo(tester, find.byKey(_noteKey));
      await tester.enterText(find.byKey(_noteKey), '  loved it  ');
      await _scrollTo(tester, find.byKey(_tagsKey));
      await tester.enterText(
        find.byKey(_tagsKey),
        'Backlog, Favorites , backlog, ,',
      );

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(_returned, isNotNull);
      expect(_returned!.comment, 'loved it');
      expect(
        _returned!.tags,
        <String>['Backlog', 'Favorites'],
      );
    });

    testWidgets('Create leaves note null and tags empty when untouched',
        (WidgetTester tester) async {
      await _openCreate(tester);

      await tester.enterText(find.byType(TextField).first, 'My Card');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(_returned, isNotNull);
      expect(_returned!.comment, isNull);
      expect(_returned!.tags, isEmpty);
    });
  });

  group('CreateCustomItemDialog edit mode', () {
    testWidgets('renders the media-type chip row when editing',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('hides the note and tags fields — they belong to the item',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));
      expect(find.byKey(_noteKey), findsNothing);
      expect(find.byKey(_tagsKey), findsNothing);
    });

    testWidgets('offers a chip for every MediaType so a new type is not forgotten',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(MediaType.values.length),
      );
    });

    testWidgets('preselects exactly one chip — the one matching displayType',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.movie));

      final Iterable<ChoiceChip> selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((ChoiceChip c) => c.selected);
      expect(selected, hasLength(1));
    });

    testWidgets('defaults to a single selected chip when displayType is null',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media());

      final Iterable<ChoiceChip> selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((ChoiceChip c) => c.selected);
      expect(selected, hasLength(1));
    });

    testWidgets('Save returns CustomItemData carrying the new mediaType',
        (WidgetTester tester) async {
      await _openEdit(tester, existing: _media(displayType: MediaType.game));

      await tester.tap(find.byType(ChoiceChip).at(_movieChipIndex));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(_returned, isNotNull);
      expect(_returned!.mediaType, MediaType.movie);
    });
  });
}
