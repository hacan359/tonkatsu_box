import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/releases/models/release_event.dart';
import 'package:tonkatsu_box/features/releases/providers/releases_provider.dart';
import 'package:tonkatsu_box/features/releases/screens/releases_screen.dart';
import 'package:tonkatsu_box/features/releases/widgets/releases_empty_state.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../../helpers/test_helpers.dart';

class _FakeReleasesNotifier extends ReleasesNotifier {
  _FakeReleasesNotifier(this._data);

  final ReleasesCalendarData _data;

  @override
  Future<ReleasesCalendarData> build() async => _data;
}

Override _override(ReleasesCalendarData data) =>
    releasesProvider.overrideWith(() => _FakeReleasesNotifier(data));

ReleaseEvent _event(DateTime date) => ReleaseEvent(
      externalId: 1,
      mediaType: MediaType.tvShow,
      showTitle: 'Show',
      season: 1,
      episode: 1,
      airDate: date,
      watched: false,
      isUpcoming: false,
      itemId: 10,
      collectionId: 2,
    );

void main() {
  group('ReleasesScreen', () {
    testWidgets('should show the empty state when nothing is tracked',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ReleasesScreen(),
        overrides: <Override>[
          _override(const ReleasesCalendarData(
            trackedCount: 0,
            events: <ReleaseEvent>[],
          )),
        ],
      );

      expect(find.byType(ReleasesEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should render the calendar without error when shows tracked',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ReleasesScreen(),
        overrides: <Override>[
          _override(ReleasesCalendarData(
            trackedCount: 1,
            events: <ReleaseEvent>[_event(DateTime(2026, 6, 2))],
          )),
        ],
      );

      expect(find.byType(ReleasesEmptyState), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should switch between month, week and day without error',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const ReleasesScreen(),
        overrides: <Override>[
          _override(ReleasesCalendarData(
            trackedCount: 1,
            events: <ReleaseEvent>[_event(DateTime(2026, 6, 2))],
          )),
        ],
      );

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
