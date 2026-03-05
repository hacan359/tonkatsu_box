import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для StatusChipRow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/status_chip_row.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

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
      testWidgets('должен вызывать onChanged с inProgress',
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

      testWidgets('должен вызывать onChanged с completed',
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

      testWidgets('должен вызывать onChanged при тапе на уже выбранный',
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
}
