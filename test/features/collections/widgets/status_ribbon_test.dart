import 'package:xerabora/l10n/app_localizations.dart';
// Тесты для StatusRibbon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/status_ribbon.dart';
import 'package:xerabora/shared/models/item_status.dart';
import 'package:xerabora/shared/models/media_type.dart';

void main() {
  Widget createWidget({
    required ItemStatus status,
    MediaType mediaType = MediaType.game,
  }) {
    return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 200,
            height: 100,
            child: Stack(
              children: <Widget>[
                StatusRibbon(
                  status: status,
                  mediaType: mediaType,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  group('StatusRibbon', () {
    group('видимость', () {
      testWidgets('не должен рендерить для notStarted',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.notStarted,
        ));

        // SizedBox.shrink вместо Positioned
        expect(find.byType(Positioned), findsNothing);
      });

      testWidgets('должен рендерить для inProgress',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
        ));

        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('должен рендерить для completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('должен рендерить для dropped',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.dropped,
        ));

        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('должен рендерить для planned',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.planned,
        ));

        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('должен рендерить для onHold',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.onHold,
          mediaType: MediaType.tvShow,
        ));

        expect(find.byType(Positioned), findsOneWidget);
      });
    });

    group('содержимое', () {
      testWidgets('должен содержать emoji статуса',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
        ));

        expect(find.textContaining(ItemStatus.inProgress.icon), findsOneWidget);
      });

      testWidgets('должен содержать текст метки для game',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.game,
        ));

        expect(find.textContaining('Playing'), findsOneWidget);
      });

      testWidgets('должен содержать текст метки для movie',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
          mediaType: MediaType.movie,
        ));

        expect(find.textContaining('Watching'), findsOneWidget);
      });

      testWidgets('должен содержать текст "Completed"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        expect(find.textContaining('Completed'), findsOneWidget);
      });

      testWidgets('должен содержать текст "Dropped"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.dropped,
        ));

        expect(find.textContaining('Dropped'), findsOneWidget);
      });

      testWidgets('должен содержать текст "Planned"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.planned,
        ));

        expect(find.textContaining('Planned'), findsOneWidget);
      });

      testWidgets('должен содержать текст "On Hold"',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.onHold,
          mediaType: MediaType.tvShow,
        ));

        expect(find.textContaining('On Hold'), findsOneWidget);
      });
    });

    group('цвет', () {
      testWidgets('должен использовать цвет статуса для фона',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        // Ищем Container с цветом statusCompleted
        final Finder containers = find.byType(Container);
        bool foundColoredContainer = false;
        for (final Element element in containers.evaluate()) {
          final Container container = element.widget as Container;
          if (container.decoration is BoxDecoration) {
            final BoxDecoration decoration =
                container.decoration! as BoxDecoration;
            if (decoration.color == ItemStatus.completed.color) {
              foundColoredContainer = true;
              break;
            }
          }
        }
        expect(foundColoredContainer, isTrue,
            reason: 'Should have container with status color');
      });
    });

    group('Transform', () {
      testWidgets('должен содержать Transform.rotate',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
        ));

        expect(find.byType(Transform), findsWidgets);
      });
    });

    group('текст', () {
      testWidgets('текст должен быть белым',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        final Text text = tester.widget<Text>(
          find.textContaining('Completed'),
        );
        expect(text.style?.color, Colors.white);
      });
    });
  });
}
