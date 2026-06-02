import 'package:tonkatsu_box/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonkatsu_box/features/collections/widgets/status_chip_row.dart';
import 'package:tonkatsu_box/shared/models/item_status.dart';
import 'package:tonkatsu_box/shared/models/media_type.dart';

void main() {
  Widget createWidget({
    required ItemStatus status,
    required MediaType mediaType,
    void Function(ItemStatus)? onChanged,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: StatusChipRow(
          status: status,
          mediaType: mediaType,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('StatusChipRow', () {
    group('тап на сегмент', () {
      testWidgets('should call onChanged с inProgress',
          (WidgetTester tester) async {
        ItemStatus? changedTo;

        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
          onChanged: (ItemStatus s) => changedTo = s,
        ));

        await tester.tap(find.byIcon(Icons.play_arrow_rounded));
        expect(changedTo, ItemStatus.inProgress);
      });

      testWidgets('should call onChanged с completed',
          (WidgetTester tester) async {
        ItemStatus? changedTo;

        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.movie,
          onChanged: (ItemStatus s) => changedTo = s,
        ));

        await tester.tap(find.byIcon(Icons.check_circle));
        expect(changedTo, ItemStatus.completed);
      });

      testWidgets('should call onChanged when tapped on the selected segment',
          (WidgetTester tester) async {
        ItemStatus? changedTo;

        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
          onChanged: (ItemStatus s) => changedTo = s,
        ));

        await tester.tap(find.byIcon(Icons.check_circle));
        expect(changedTo, ItemStatus.completed);
      });
    });
  });

  group('tryDecodeStatusMenuValue', () {
    test('should decode the status when value carries the status prefix', () {
      expect(
        tryDecodeStatusMenuValue('status:completed'),
        ItemStatus.completed,
      );
    });

    test('should return null when value is an ordinary menu action', () {
      expect(tryDecodeStatusMenuValue('remove'), isNull);
    });

    test('should fall back to notStarted for an unknown status payload', () {
      expect(tryDecodeStatusMenuValue('status:bogus'), ItemStatus.notStarted);
    });
  });
}
