import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для StatusChipRow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/status_chip_row.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';
import 'package:xerabora/shared/theme/app_colors.dart';

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
    group('сегменты', () {
      testWidgets('должен показывать 5 сегментов с иконками',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
        ));

        expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      });

      testWidgets('все сегменты одинаковой ширины (Expanded)',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
        ));

        expect(find.byType(Expanded), findsNWidgets(5));
      });
    });

    group('выбранный сегмент', () {
      testWidgets('должен иметь белую иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
        ));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.check_circle),
        );
        expect(icon.color, Colors.white);
      });
    });

    group('невыбранный сегмент', () {
      testWidgets('должен иметь приглушённую иконку',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
        ));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.radio_button_unchecked),
        );
        expect(icon.color, AppColors.textSecondary.withAlpha(140));
      });
    });

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

    group('tooltip', () {
      testWidgets('должен иметь Tooltip на каждом сегменте',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
        ));

        expect(find.byType(Tooltip), findsNWidgets(5));
      });
    });
  });
}
