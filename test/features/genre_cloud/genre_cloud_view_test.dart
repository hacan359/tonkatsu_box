import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet.dart';
import 'package:tonkatsu_box/features/genre_cloud/facet_value.dart';
import 'package:tonkatsu_box/features/genre_cloud/widgets/genre_cloud_view.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

import '../../helpers/test_helpers.dart';

List<FacetValue> _sample() => const <FacetValue>[
      FacetValue(
          facet: Facet.genre,
          label: 'Action',
          count: 40,
          type: MediaType.anime),
      FacetValue(
          facet: Facet.platform,
          label: 'PlayStation',
          count: 33,
          type: MediaType.game),
      FacetValue(
          facet: Facet.decade,
          label: '2010s',
          count: 21,
          type: MediaType.movie),
      FacetValue(
          facet: Facet.genre,
          label: 'Comedy',
          count: 12,
          type: MediaType.tvShow),
      FacetValue(
          facet: Facet.genre,
          label: 'Drama',
          count: 6,
          type: MediaType.book),
    ];

void main() {
  group('GenreCloudView', () {
    testWidgets('renders a populated cloud without exceptions', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SizedBox(
          width: 360,
          height: 560,
          child: GenreCloudView(words: _sample()),
        ),
        mediaQuerySize: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(GenreCloudView), findsOneWidget);
    });

    testWidgets('renders an empty cloud without exceptions', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        const SizedBox(
          width: 360,
          height: 560,
          child: GenreCloudView(words: <FacetValue>[]),
        ),
        mediaQuerySize: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('is pannable/zoomable by default (interactive)', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SizedBox(
          width: 360,
          height: 560,
          child: GenreCloudView(words: _sample()),
        ),
        mediaQuerySize: const Size(360, 640),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('is static when interactive is false (export poster)', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        SizedBox(
          width: 1200,
          height: 800,
          child: GenreCloudView(words: _sample(), interactive: false),
        ),
        mediaQuerySize: const Size(1200, 800),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(InteractiveViewer), findsNothing);
    });
  });
}
