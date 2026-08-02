import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/statistics/models/library_stats.dart';
import 'package:tonkatsu_box/features/statistics/widgets/stats_period_picker.dart';

import '../../../helpers/test_helpers.dart';

/// Lets the picker take its intrinsic size; as `MaterialApp.home` it fills the
/// screen, hiding its real width and moving its centre off the anchor.
Widget _pinned(Widget child) =>
    Align(alignment: Alignment.topLeft, child: child);

void main() {
  group('StatsPeriodPicker', () {
    const List<StatsPeriod> periods = <StatsPeriod>[
      StatsPeriod.allTime(),
      StatsPeriod.year(2024),
      StatsPeriod.year(2023),
    ];

    StatsPeriodPickerData data({
      StatsPeriod selected = const StatsPeriod.allTime(),
      ValueChanged<StatsPeriod>? onChanged,
      Widget? trailing,
    }) {
      return StatsPeriodPickerData(
        periods: periods,
        selected: selected,
        onChanged: onChanged ?? (_) {},
        trailing: trailing,
      );
    }

    testWidgets('should keep the years out of the layout until opened', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(_pinned(StatsPeriodPicker(data: data())));

      // Only the anchor's own label is on screen; the years live in the menu,
      // which has not been opened.
      expect(find.text('2024'), findsNothing);
      expect(find.text('2023'), findsNothing);
    });

    testWidgets('should report the period chosen from the menu', (
      WidgetTester tester,
    ) async {
      StatsPeriod? chosen;
      await tester.pumpApp(
        _pinned(
          StatsPeriodPicker(
            data: data(onChanged: (StatsPeriod p) => chosen = p),
          ),
        ),
      );

      await tester.tap(find.byType(StatsPeriodPicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2023').last);
      await tester.pumpAndSettle();

      expect(chosen, const StatsPeriod.year(2023));
    });

    testWidgets('should keep its size as periods are added', (
      WidgetTester tester,
    ) async {
      // The point of the dropdown over a tab row: ten years cost the layout
      // exactly as much as two.
      await tester.pumpApp(_pinned(StatsPeriodPicker(data: data())));
      final Size small = tester.getSize(find.byType(StatsPeriodPicker));

      await tester.pumpApp(
        _pinned(
          StatsPeriodPicker(
            data: StatsPeriodPickerData(
              periods: <StatsPeriod>[
                const StatsPeriod.allTime(),
                for (int year = 2015; year <= 2024; year++)
                  StatsPeriod.year(year),
              ],
              selected: const StatsPeriod.allTime(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(StatsPeriodPicker)), small);
    });

    testWidgets('should render the trailing action beside the dropdown', (
      WidgetTester tester,
    ) async {
      await tester.pumpApp(
        _pinned(
          StatsPeriodPicker(data: data(trailing: const Icon(Icons.ios_share))),
        ),
      );

      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });
  });
}
