import 'package:core/models/item_mark.dart';
import 'package:core/models/marked_unit.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/likes/providers/marked_units_provider.dart';
import 'package:tonkatsu_box/features/personalization/widgets/hub_likes_preview.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';

import '../../../helpers/test_helpers.dart';

MarkedUnitGroup _marked(int id, String name) => MarkedUnitGroup(
      item: createTestCollectionItem(id: id, mediaType: MediaType.anime)
          .copyWith(overrideName: name),
      units: <MarkedUnit>[
        MarkedUnit(
          mark: ItemMark(
            id: 0,
            itemId: id,
            unitType: kUnitEpisode,
            parentNumber: 1,
            unitNumber: 1,
            isFavorite: true,
            likedAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
        ),
      ],
    );

MarkedUnitGroup _replayed(int id, String name, int count) => MarkedUnitGroup(
      item: createTestCollectionItem(id: id, mediaType: MediaType.movie)
          .copyWith(overrideName: name, rewatchCount: count),
      units: const <MarkedUnit>[],
      rewatchCount: count,
    );

void main() {
  group('HubLikesPreview', () {
    Future<S> pump(
      WidgetTester tester,
      List<MarkedUnitGroup> groups,
    ) async {
      await tester.pumpApp(
        const HubLikesPreview(),
        overrides: <Override>[
          likesEntriesProvider.overrideWithValue(
            AsyncValue<List<MarkedUnitGroup>>.data(groups),
          ),
        ],
        wrapInScaffold: true,
      );
      await tester.pumpAndSettle();
      return S.of(tester.element(find.byType(HubLikesPreview)));
    }

    testWidgets('should render a replay-only title without a unit',
        (WidgetTester tester) async {
      final S l = await pump(tester, <MarkedUnitGroup>[
        _replayed(2, 'Replayed movie', 3),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Replayed movie'), findsOneWidget);
      expect(find.textContaining(l.likesRewatchTimes(3)), findsOneWidget);
    });

    testWidgets('should count a replay as one entry next to the marks',
        (WidgetTester tester) async {
      final S l = await pump(tester, <MarkedUnitGroup>[
        _marked(1, 'Marked show'),
        _replayed(2, 'Replayed movie', 1),
      ]);

      expect(find.text(l.likesMarkCount(2)), findsOneWidget);
      expect(find.textContaining('Marked show'), findsOneWidget);
      expect(find.textContaining('Replayed movie'), findsOneWidget);
    });

    testWidgets('should show only the two freshest entries',
        (WidgetTester tester) async {
      await pump(tester, <MarkedUnitGroup>[
        _marked(1, 'First'),
        _marked(2, 'Second'),
        _replayed(3, 'Third', 2),
      ]);

      expect(find.textContaining('First'), findsOneWidget);
      expect(find.textContaining('Second'), findsOneWidget);
      expect(find.textContaining('Third'), findsNothing);
    });
  });
}
