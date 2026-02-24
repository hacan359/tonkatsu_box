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
    group('количество чипов', () {
      testWidgets('для game должен показывать 5 чипов',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
        ));

        // 5 статусов: notStarted, inProgress, completed, dropped, planned
        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Playing'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
      });

      testWidgets('для movie должен показывать 5 чипов',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.movie,
        ));

        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
      });

      testWidgets('для tvShow должен показывать 5 чипов',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.tvShow,
        ));

        expect(find.text('Not Started'), findsOneWidget);
        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Dropped'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
      });
    });

    group('выбранный чип', () {
      testWidgets('должен иметь цветной фон',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.game,
        ));

        // Ищем AnimatedContainer с цветом statusInProgress
        final Finder playingChip = find.ancestor(
          of: find.text('Playing'),
          matching: find.byType(AnimatedContainer),
        );
        expect(playingChip, findsOneWidget);

        final AnimatedContainer container =
            tester.widget<AnimatedContainer>(playingChip);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.border,
          isA<Border>().having(
            (Border b) => b.top.color,
            'border color',
            AppColors.statusInProgress,
          ),
        );
      });

      testWidgets('должен иметь жирный текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
        ));

        final Text completedText = tester.widget<Text>(
          find.text('Completed'),
        );
        expect(completedText.style?.fontWeight, FontWeight.w600);
      });
    });

    group('невыбранный чип', () {
      testWidgets('должен иметь обычный текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
        ));

        // "Not Started" — невыбранный
        final Text notStartedText = tester.widget<Text>(
          find.text('Not Started'),
        );
        expect(notStartedText.style?.fontWeight, FontWeight.normal);
      });

      testWidgets('должен иметь surfaceBorder рамку',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
          mediaType: MediaType.game,
        ));

        final Finder notStartedChip = find.ancestor(
          of: find.text('Not Started'),
          matching: find.byType(AnimatedContainer),
        );

        final AnimatedContainer container =
            tester.widget<AnimatedContainer>(notStartedChip);
        final BoxDecoration decoration =
            container.decoration! as BoxDecoration;
        expect(
          decoration.border,
          isA<Border>().having(
            (Border b) => b.top.color,
            'border color',
            AppColors.surfaceBorder,
          ),
        );
      });
    });

    group('тап на чип', () {
      testWidgets('должен вызывать onChanged с правильным статусом',
          (WidgetTester tester) async {
        ItemStatus? changedTo;

        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.game,
          onChanged: (ItemStatus s) => changedTo = s,
        ));

        await tester.tap(find.text('Playing'));
        expect(changedTo, ItemStatus.inProgress);
      });

      testWidgets('должен вызывать onChanged при тапе на Completed',
          (WidgetTester tester) async {
        ItemStatus? changedTo;

        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.movie,
          onChanged: (ItemStatus s) => changedTo = s,
        ));

        await tester.tap(find.text('Completed'));
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

        await tester.tap(find.text('Completed'));
        expect(changedTo, ItemStatus.completed);
      });
    });

    group('emoji иконки', () {
      testWidgets('каждый чип должен содержать emoji',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
          mediaType: MediaType.tvShow,
        ));

        for (final ItemStatus status in ItemStatus.values) {
          expect(
            find.text(status.icon),
            findsOneWidget,
            reason: '${status.name} should have icon',
          );
        }
      });
    });

    group('медиа-зависимые метки', () {
      testWidgets('для game inProgress должен показывать "Playing"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.game,
        ));

        expect(find.text('Playing'), findsOneWidget);
        expect(find.text('Watching'), findsNothing);
      });

      testWidgets('для movie inProgress должен показывать "Watching"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.movie,
        ));

        expect(find.text('Watching'), findsOneWidget);
        expect(find.text('Playing'), findsNothing);
      });

      testWidgets('для tvShow inProgress должен показывать "Watching"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.tvShow,
        ));

        expect(find.text('Watching'), findsOneWidget);
      });
    });
  });
}
