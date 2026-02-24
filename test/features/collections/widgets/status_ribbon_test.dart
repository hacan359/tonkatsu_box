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
    });

    group('содержимое', () {
      testWidgets('должен содержать Material-иконку статуса',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.inProgress,
        ));

        expect(
          find.byIcon(ItemStatus.inProgress.materialIcon),
          findsOneWidget,
        );
      });

      testWidgets('должен показывать иконку completed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('должен показывать иконку dropped',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.dropped,
        ));

        expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
      });

      testWidgets('должен показывать иконку planned',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.planned,
        ));

        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      });
    });

    group('цвет', () {
      testWidgets('должен использовать цвет статуса для фона',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

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

      testWidgets('иконка должна быть белой', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          status: ItemStatus.completed,
        ));

        final Icon icon = tester.widget<Icon>(
          find.byIcon(Icons.check_circle),
        );
        expect(icon.color, Colors.white);
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
  });
}
