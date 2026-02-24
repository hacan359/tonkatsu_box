import 'package:xerabora/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_link_item.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  group('CanvasLinkItem', () {
    final DateTime testDate = DateTime(2024, 6, 15);

    CanvasItem createLinkItem({
      Map<String, dynamic>? data,
      double? width,
      double? height,
    }) {
      return CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.link,
        x: 100,
        y: 100,
        width: width,
        height: height,
        data: data,
        createdAt: testDate,
      );
    }

    Widget buildWidget(CanvasItem item) {
      return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: CanvasLinkItem(item: item),
          ),
        ),
      );
    }

    testWidgets(
      'должен показать Card',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Example',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byType(Card), findsOneWidget);
      },
    );

    testWidgets(
      'должен отображать label',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'My Website',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('My Website'), findsOneWidget);
      },
    );

    testWidgets(
      'должен показывать url если label отсутствует',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{'url': 'https://example.com'},
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('https://example.com'), findsOneWidget);
      },
    );

    testWidgets(
      'должен показывать "Link" если data null',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(data: null);

        await tester.pumpWidget(buildWidget(item));

        expect(find.text('Link'), findsOneWidget);
      },
    );

    testWidgets(
      'должен показывать иконку ссылки',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Test',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byIcon(Icons.link), findsOneWidget);
      },
    );

    testWidgets(
      'должен рендерить Card без явного SizedBox (размер от родителя)',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Test',
          },
          width: null,
          height: null,
        );

        await tester.pumpWidget(buildWidget(item));

        // Card рендерится, размеры определяются родителем Positioned
        expect(find.byType(Card), findsOneWidget);
        // Row внутри Card содержит иконку и текст
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
      },
    );

    testWidgets(
      'должен рендерить Card при custom размерах',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Test',
          },
          width: 300,
          height: 60,
        );

        await tester.pumpWidget(buildWidget(item));

        // Card рендерится (размеры задаются родителем Positioned)
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('Test'), findsOneWidget);
      },
    );

    testWidgets(
      'должен содержать GestureDetector для doubleTap',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Test',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byType(GestureDetector), findsOneWidget);
      },
    );

    testWidgets(
      'должен иметь подчёркнутый текст',
      (WidgetTester tester) async {
        final CanvasItem item = createLinkItem(
          data: <String, dynamic>{
            'url': 'https://example.com',
            'label': 'Underlined',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        final Text textWidget =
            tester.widget<Text>(find.text('Underlined'));
        expect(textWidget.style?.decoration, TextDecoration.underline);
      },
    );
  });
}
