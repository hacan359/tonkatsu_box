import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/media_type_dots.dart';
import 'package:tonkatsu_box/shared/constants/media_type_theme.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MediaTypeDots', () {
    testWidgets('should render nothing when types is empty',
        (WidgetTester tester) async {
      // Center gives loose constraints, so "renders nothing" is measurable.
      await tester.pumpApp(
        const Center(child: MediaTypeDots(types: <MediaType>[])),
      );

      expect(find.byType(MediaTypeDots), findsOneWidget);
      expect(tester.getSize(find.byType(MediaTypeDots)), Size.zero);
    });

    testWidgets('should render one dot per type up to five',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const MediaTypeDots(
          types: <MediaType>[
            MediaType.game,
            MediaType.movie,
            MediaType.book,
          ],
        ),
      );

      expect(find.byIcon(MediaTypeTheme.iconFor(MediaType.game)),
          findsOneWidget);
      expect(find.byIcon(MediaTypeTheme.iconFor(MediaType.movie)),
          findsOneWidget);
      expect(find.byIcon(MediaTypeTheme.iconFor(MediaType.book)),
          findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('should not overflow-badge at exactly five types',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const MediaTypeDots(
          types: <MediaType>[
            MediaType.game,
            MediaType.movie,
            MediaType.tvShow,
            MediaType.anime,
            MediaType.book,
          ],
        ),
      );

      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('should collapse the tail into +N beyond five types',
        (WidgetTester tester) async {
      await tester.pumpApp(
        MediaTypeDots(types: MediaType.values.toList()),
      );

      // 9 types: 4 dots + one "+5" badge, so a single type is never
      // replaced by the counter alone.
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('should render without exceptions', (WidgetTester tester) async {
      await tester.pumpApp(
        MediaTypeDots(types: MediaType.values.toList(), dotSize: 24),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
