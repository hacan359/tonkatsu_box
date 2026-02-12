// Тесты для ShimmerLoading виджетов.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/widgets/shimmer_loading.dart';

void main() {
  group('ShimmerBox', () {
    testWidgets('должен рендериться с заданными размерами',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 100, height: 50),
          ),
        ),
      );

      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('должен содержать Container',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 100, height: 50),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('анимация должна работать',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerBox(width: 100, height: 50),
          ),
        ),
      );

      // Прокрутить анимацию
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShimmerBox), findsOneWidget);
    });
  });

  group('ShimmerPosterCard', () {
    testWidgets('должен рендериться', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ShimmerPosterCard(),
            ),
          ),
        ),
      );

      expect(find.byType(ShimmerPosterCard), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('должен содержать ShimmerBox элементы',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: ShimmerPosterCard(),
            ),
          ),
        ),
      );

      // Постер + 2 строки текста = 3 ShimmerBox
      expect(find.byType(ShimmerBox), findsNWidgets(3));
    });
  });

  group('ShimmerListTile', () {
    testWidgets('должен рендериться', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerListTile(),
          ),
        ),
      );

      expect(find.byType(ShimmerListTile), findsOneWidget);
    });

    testWidgets('должен содержать Row с ShimmerBox элементами',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerListTile(),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      // Постер + 3 строки текста = 4 ShimmerBox
      expect(find.byType(ShimmerBox), findsNWidgets(4));
    });
  });
}
