import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';
import 'package:tonkatsu_box/features/statistics/providers/statistics_provider.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_month_detail_dialog.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  const MonthDetail detail = MonthDetail(
    year: 2026,
    month: 7,
    weeks: <Map<MediaType, int>>[
      <MediaType, int>{MediaType.game: 3, MediaType.movie: 2},
      <MediaType, int>{MediaType.tvShow: 5},
      <MediaType, int>{MediaType.anime: 1, MediaType.manga: 4},
      <MediaType, int>{MediaType.book: 2},
      <MediaType, int>{MediaType.game: 1},
    ],
    totalAdded: 18,
  );

  Widget dialog() => const StatsMonthDetailDialog(
        year: 2026,
        month: 7,
        episodesWatched: 12,
      );

  group('StatsMonthDetailDialog', () {
    testWidgets('should render all five week bars without exceptions',
        (WidgetTester tester) async {
      await tester.pumpApp(
        dialog(),
        overrides: <Override>[
          monthDetailProvider.overrideWith(
            (Ref ref, (int, int) key) async => detail,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('1–7'), findsOneWidget);
      expect(find.text('29+'), findsOneWidget);
    });

    testWidgets('should not overflow on a phone-sized screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpApp(
        dialog(),
        overrides: <Override>[
          monthDetailProvider.overrideWith(
            (Ref ref, (int, int) key) async => detail,
          ),
        ],
      );

      expect(tester.takeException(), isNull);
    });
  });
}
