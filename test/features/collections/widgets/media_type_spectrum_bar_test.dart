import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/media_type_spectrum_bar.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MediaTypeSpectrumBar', () {
    testWidgets('should render nothing for empty counts',
        (WidgetTester tester) async {
      // Center gives loose constraints, so "renders nothing" is measurable.
      await tester.pumpApp(
        const Center(child: MediaTypeSpectrumBar(counts: <MediaType, int>{})),
      );

      expect(
        tester.getSize(find.byType(MediaTypeSpectrumBar)),
        Size.zero,
      );
    });

    testWidgets('should render nothing when all counts are zero',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(
          child: MediaTypeSpectrumBar(
            counts: <MediaType, int>{MediaType.game: 0, MediaType.book: 0},
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(MediaTypeSpectrumBar)),
        Size.zero,
      );
    });

    testWidgets('should render one segment per type with items',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 200,
            child: MediaTypeSpectrumBar(
              counts: <MediaType, int>{
                MediaType.game: 7,
                MediaType.movie: 2,
                MediaType.anime: 0,
              },
            ),
          ),
        ),
      );

      final Finder segments = find.descendant(
        of: find.byType(MediaTypeSpectrumBar),
        matching: find.byType(ColoredBox),
      );
      expect(segments, findsNWidgets(2));
    });

    testWidgets('should size segments proportionally to counts',
        (WidgetTester tester) async {
      await tester.pumpApp(
        const Center(
          child: SizedBox(
            width: 200,
            child: MediaTypeSpectrumBar(
              counts: <MediaType, int>{
                MediaType.game: 3,
                MediaType.movie: 1,
              },
            ),
          ),
        ),
      );

      final Finder segments = find.descendant(
        of: find.byType(MediaTypeSpectrumBar),
        matching: find.byType(ColoredBox),
      );
      final double first = tester.getSize(segments.at(0)).width;
      final double second = tester.getSize(segments.at(1)).width;

      // 3:1 flex split of the width remaining after the segment gap.
      expect(first / second, closeTo(3, 0.05));
    });
  });
}
