import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/features/collections/widgets/canvas_image_item.dart';
import 'package:xerabora/shared/models/canvas_item.dart';

void main() {
  group('CanvasImageItem', () {
    final DateTime testDate = DateTime(2024, 6, 15);

    CanvasItem createImageItem({
      Map<String, dynamic>? data,
      double? width,
      double? height,
    }) {
      return CanvasItem(
        id: 1,
        collectionId: 10,
        itemType: CanvasItemType.image,
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
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: CanvasImageItem(item: item),
          ),
        ),
      );
    }

    testWidgets(
      'должен показать Card',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{'url': 'https://example.com/image.png'},
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byType(Card), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать placeholder иконку когда data null',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(data: null);

        await tester.pumpWidget(buildWidget(item));

        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать placeholder иконку когда data пустой',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{},
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать placeholder иконку когда url пустой',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{'url': ''},
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'должен показать Image.memory для base64 данных',
      (WidgetTester tester) async {
        // Создаём минимальный PNG (1x1 пиксель)
        final String base64Png = base64Encode(<int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
          0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
          0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
          0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
          0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
          0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
          0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
          0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, // IEND chunk
          0x44, 0xAE, 0x42, 0x60, 0x82,
        ]);

        final CanvasItem item = createImageItem(
          data: <String, dynamic>{
            'base64': base64Png,
            'mimeType': 'image/png',
          },
        );

        await tester.pumpWidget(buildWidget(item));

        expect(find.byType(Image), findsOneWidget);
      },
    );

    testWidgets(
      'должен использовать SizedBox.expand для заполнения родителя',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{'url': 'https://example.com/image.png'},
          width: null,
          height: null,
        );

        await tester.pumpWidget(buildWidget(item));

        // SizedBox.expand() внутри Card — расширяется до размеров родителя
        final SizedBox sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(SizedBox),
          ).first,
        );
        expect(sizedBox.width, double.infinity);
        expect(sizedBox.height, double.infinity);
      },
    );

    testWidgets(
      'должен рендерить Card с изображением при custom размерах',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{'url': 'https://example.com/image.png'},
          width: 300,
          height: 150,
        );

        await tester.pumpWidget(buildWidget(item));

        // Card рендерится (размеры задаются родителем Positioned)
        expect(find.byType(Card), findsOneWidget);
        // SizedBox.expand внутри
        final SizedBox sizedBox = tester.widget<SizedBox>(
          find.descendant(
            of: find.byType(Card),
            matching: find.byType(SizedBox),
          ).first,
        );
        expect(sizedBox.width, double.infinity);
        expect(sizedBox.height, double.infinity);
      },
    );

    testWidgets(
      'должен иметь clipBehavior antiAlias на Card',
      (WidgetTester tester) async {
        final CanvasItem item = createImageItem(
          data: <String, dynamic>{'url': 'https://example.com/image.png'},
        );

        await tester.pumpWidget(buildWidget(item));

        final Card card = tester.widget<Card>(find.byType(Card));
        expect(card.clipBehavior, Clip.antiAlias);
      },
    );
  });
}
