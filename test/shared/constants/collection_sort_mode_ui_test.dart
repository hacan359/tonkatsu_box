import 'package:core/models/collection_sort_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/l10n/app_localizations.dart';
import 'package:tonkatsu_box/shared/constants/collection_sort_mode_ui.dart';

void main() {
  group('CollectionSortModeUi', () {
    group('localizedDirectionLabel', () {
      Future<S> loadLocalizations(WidgetTester tester) async {
        late S l;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: Builder(
              builder: (BuildContext context) {
                l = S.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        return l;
      }

      testWidgets('spells out a non-empty label that changes with direction',
          (WidgetTester tester) async {
        final S l = await loadLocalizations(tester);

        for (final CollectionSortMode mode in CollectionSortMode.values) {
          final String forward =
              mode.localizedDirectionLabel(l, descending: false);
          final String reverse =
              mode.localizedDirectionLabel(l, descending: true);

          expect(forward, isNotEmpty);
          expect(reverse, isNotEmpty);
          if (mode == CollectionSortMode.manual) {
            // Manual order is not reversible, so both directions read the same.
            expect(forward, reverse);
          } else {
            expect(forward, isNot(reverse));
          }
        }
      });
    });
  });
}
