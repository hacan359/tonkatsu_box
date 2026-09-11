import 'package:core/models/data_source.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/showcase/models/showcase_item.dart';
import 'package:tonkatsu_box/features/showcase/providers/showcase_clock_provider.dart';
import 'package:tonkatsu_box/features/showcase/widgets/release_board.dart';
import 'package:tonkatsu_box/features/showcase/widgets/release_card.dart';

import '../../../helpers/test_helpers.dart';

final DateTime _now = DateTime(2026, 9, 11, 12);

ShowcaseItem _item(
  int id, {
  DateTime? nextDate,
  int? nextSeason,
  int? nextEpisode,
  bool hasTimeOfDay = false,
  MediaType type = MediaType.anime,
  String? description,
}) =>
    ShowcaseItem(
      media: Object(),
      mediaType: type,
      source: DataSource.anilist,
      externalId: id,
      title: 'Item $id',
      nextDate: nextDate,
      nextSeason: nextSeason,
      nextEpisode: nextEpisode,
      hasTimeOfDay: hasTimeOfDay,
      description: description,
    );

List<Override> _fixedClock() => <Override>[
      showcaseClockProvider.overrideWithValue(() => _now),
    ];

Widget _board(
  List<ShowcaseItem> items, {
  bool allowsDayGrouping = false,
}) =>
    SingleChildScrollView(
      child: ReleaseBoard(
        title: 'Board',
        items: items,
        allowsDayGrouping: allowsDayGrouping,
        onTap: (_) {},
      ),
    );

void main() {
  group('ReleaseCard', () {
    testWidgets('prints the episode and a days-hours countdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(
            1,
            nextEpisode: 5,
            hasTimeOfDay: true,
            nextDate: _now.add(const Duration(days: 2, hours: 4)),
          ),
        ]),
        overrides: _fixedClock(),
      );

      expect(find.text('Ep 5 · in 2d 4h'), findsOneWidget);
    });

    testWidgets('a TV episode prints season and episode with whole days', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(
            1,
            type: MediaType.tvShow,
            nextSeason: 4,
            nextEpisode: 8,
            nextDate: DateTime(2026, 9, 16),
          ),
        ]),
        overrides: _fixedClock(),
      );

      expect(find.text('S4E8 · in 5d'), findsOneWidget);
    });

    testWidgets('a date-only release counts whole days and says Today', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(1, type: MediaType.game, nextDate: DateTime(2026, 9, 11)),
          _item(2, type: MediaType.movie, nextDate: DateTime(2026, 9, 23)),
        ]),
        overrides: _fixedClock(),
      );

      expect(find.text('Release · Today'), findsOneWidget);
      expect(find.text('Premiere · in 12d'), findsOneWidget);
    });

    testWidgets('a passed date reads Out now; no date shows no headline', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(1, type: MediaType.movie, nextDate: DateTime(2026, 9, 1)),
          _item(2),
        ]),
        overrides: _fixedClock(),
      );

      expect(find.text('Premiere · Out now'), findsOneWidget);
      expect(find.textContaining('·'), findsOneWidget);
    });

    testWidgets('lays out on a phone with a long description', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(
            1,
            nextEpisode: 5,
            hasTimeOfDay: true,
            nextDate: _now.add(const Duration(hours: 3)),
            description: 'word ' * 200,
          ),
        ]),
        overrides: _fixedClock(),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ReleaseBoard', () {
    testWidgets('soonest card comes first, undated last', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[
          _item(1),
          _item(2, nextDate: DateTime(2026, 9, 20)),
          _item(3, nextDate: DateTime(2026, 9, 12)),
        ]),
        overrides: _fixedClock(),
      );

      final double y3 = tester.getTopLeft(find.text('Item 3')).dy;
      final double y2 = tester.getTopLeft(find.text('Item 2')).dy;
      final double y1 = tester.getTopLeft(find.text('Item 1')).dy;
      expect(y3, lessThanOrEqualTo(y2));
      expect(y2, lessThanOrEqualTo(y1));
    });

    testWidgets('collapses past the limit and expands on Show all', (
      WidgetTester tester,
    ) async {
      final List<ShowcaseItem> items = <ShowcaseItem>[
        for (int i = 1; i <= releaseBoardCollapsedCount + 2; i++)
          _item(i, nextDate: DateTime(2026, 9, 11 + i)),
      ];
      await tester.pumpApp(_board(items), overrides: _fixedClock());

      expect(find.byType(ReleaseCard), findsNWidgets(releaseBoardCollapsedCount));

      await tester.tap(find.text('Show all (${items.length})'));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseCard), findsNWidgets(items.length));
      expect(find.text('Collapse'), findsOneWidget);
    });

    testWidgets('a short list has no Show all button', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[_item(1), _item(2)]),
        overrides: _fixedClock(),
      );

      expect(find.textContaining('Show all'), findsNothing);
    });

    testWidgets('by-day view adds a heading per day and a TBA tail', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(
          <ShowcaseItem>[
            _item(1, nextDate: DateTime(2026, 9, 12, 20)),
            _item(2, nextDate: DateTime(2026, 9, 12, 22)),
            _item(3, nextDate: DateTime(2026, 9, 14, 9)),
            _item(4),
          ],
          allowsDayGrouping: true,
        ),
        overrides: _fixedClock(),
      );

      expect(find.text('Date TBA'), findsNothing);

      await tester.tap(find.byIcon(Icons.calendar_view_day_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Saturday, 12 Sep'), findsOneWidget);
      expect(find.text('Monday, 14 Sep'), findsOneWidget);
      expect(find.text('Date TBA'), findsOneWidget);
      expect(find.byType(ReleaseCard), findsNWidgets(4));
    });

    testWidgets('by-day view shows every day, not just the collapsed head', (
      WidgetTester tester,
    ) async {
      final List<ShowcaseItem> items = <ShowcaseItem>[
        for (int i = 1; i <= releaseBoardCollapsedCount + 3; i++)
          _item(i, nextDate: DateTime(2026, 9, 11 + i)),
      ];
      await tester.pumpApp(
        _board(items, allowsDayGrouping: true),
        overrides: _fixedClock(),
      );
      expect(
        find.byType(ReleaseCard),
        findsNWidgets(releaseBoardCollapsedCount),
      );

      await tester.tap(find.byIcon(Icons.calendar_view_day_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(ReleaseCard), findsNWidgets(items.length));
      expect(find.textContaining('Show all'), findsNothing);
    });

    testWidgets('the view toggle is absent unless the row allows it', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _board(<ShowcaseItem>[_item(1)]),
        overrides: _fixedClock(),
      );

      expect(find.byIcon(Icons.calendar_view_day_outlined), findsNothing);
    });

    testWidgets('empty items render nothing', (WidgetTester tester) async {
      await tester.pumpApp(
        _board(const <ShowcaseItem>[]),
        overrides: _fixedClock(),
      );

      expect(find.text('Board'), findsNothing);
    });
  });
}
