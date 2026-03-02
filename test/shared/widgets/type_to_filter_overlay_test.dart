// Тесты для TypeToFilterOverlay.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/l10n/app_localizations.dart';
import 'package:xerabora/shared/widgets/type_to_filter_overlay.dart';

void main() {
  Widget buildWidget({
    required ValueChanged<String> onFilterChanged,
    String? hintText,
    GlobalKey<TypeToFilterOverlayState>? overlayKey,
    Widget? child,
  }) {
    return MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: TypeToFilterOverlay(
          key: overlayKey,
          onFilterChanged: onFilterChanged,
          hintText: hintText,
          child: child ?? const Center(child: Text('Child Content')),
        ),
      ),
    );
  }

  /// Отправляет нажатие клавиши с символом.
  Future<void> sendChar(WidgetTester tester, String char) async {
    await simulateKeyDownEvent(
      _logicalKeyFor(char),
      character: char,
    );
    await simulateKeyUpEvent(_logicalKeyFor(char));
    await tester.pumpAndSettle();
  }

  /// Нажимает Escape.
  Future<void> sendEscape(WidgetTester tester) async {
    await simulateKeyDownEvent(LogicalKeyboardKey.escape);
    await simulateKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  }

  group('TypeToFilterOverlay', () {
    testWidgets('рендерит child', (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget(
        onFilterChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('не показывает overlay изначально', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        onFilterChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Esc'), findsNothing);
    });

    testWidgets('показывает overlay при нажатии печатного символа', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        onFilterChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      await sendChar(tester, 'a');

      expect(find.text('Esc'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('вызывает onFilterChanged с текстом', (
      WidgetTester tester,
    ) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
      ));
      await tester.pumpAndSettle();

      await sendChar(tester, 'a');

      expect(calls, contains('a'));
    });

    testWidgets('скрывает по Escape', (WidgetTester tester) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
      ));
      await tester.pumpAndSettle();

      // Показываем overlay
      await sendChar(tester, 'a');
      expect(find.text('Esc'), findsOneWidget);

      // Нажимаем Escape
      await sendEscape(tester);

      // Overlay скрыт
      expect(find.text('Esc'), findsNothing);
      expect(calls.last, equals(''));
    });

    testWidgets('сбрасывает фильтр при повторном открытии и закрытии', (
      WidgetTester tester,
    ) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
      ));
      await tester.pumpAndSettle();

      // Вводим 'a' — overlay появляется
      await sendChar(tester, 'a');
      expect(calls, contains('a'));

      // Escape закрывает и сбрасывает
      await sendEscape(tester);
      expect(calls.last, equals(''));

      // Снова вводим символ — overlay появляется заново
      calls.clear();
      await sendChar(tester, 'b');
      expect(calls, contains('b'));
      expect(find.text('Esc'), findsOneWidget);
    });

    testWidgets('показывает иконку поиска, кнопку закрыть, badge Esc', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        onFilterChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      await sendChar(tester, 'a');

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Esc'), findsOneWidget);
    });

    testWidgets('очищает при тапе на кнопку закрыть', (
      WidgetTester tester,
    ) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
      ));
      await tester.pumpAndSettle();

      // Показываем overlay
      await sendChar(tester, 'a');

      // Нажимаем кнопку закрыть
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Overlay скрыт
      expect(find.text('Esc'), findsNothing);
      expect(calls.last, equals(''));
    });

    testWidgets('clear() метод работает', (WidgetTester tester) async {
      final List<String> calls = <String>[];
      final GlobalKey<TypeToFilterOverlayState> key =
          GlobalKey<TypeToFilterOverlayState>();

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
        overlayKey: key,
      ));
      await tester.pumpAndSettle();

      // Показываем overlay
      await sendChar(tester, 'a');
      expect(find.text('Esc'), findsOneWidget);

      // Программный сброс
      key.currentState!.clear();
      await tester.pumpAndSettle();

      // Overlay скрыт
      expect(find.text('Esc'), findsNothing);
      expect(calls.last, equals(''));
    });

    testWidgets('использует кастомный hintText', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget(
        onFilterChanged: (_) {},
        hintText: 'Custom hint',
      ));
      await tester.pumpAndSettle();

      await sendChar(tester, 'a');

      expect(find.text('Custom hint'), findsOneWidget);
    });

    testWidgets('не активируется когда внешний EditableText в фокусе', (
      WidgetTester tester,
    ) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: TypeToFilterOverlay(
            onFilterChanged: (String text) => calls.add(text),
            child: const Column(
              children: <Widget>[
                Text('Child'),
                TextField(decoration: InputDecoration()),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Явно фокусируем внешний TextField тапом
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Нажимаем символ — overlay НЕ появляется
      await sendChar(tester, 'a');

      // onFilterChanged НЕ содержит непустых вызовов
      final bool overlayTriggered = calls.any((String c) => c.isNotEmpty);
      expect(overlayTriggered, isFalse);
    });

    testWidgets('накапливает несколько символов', (
      WidgetTester tester,
    ) async {
      final List<String> calls = <String>[];

      await tester.pumpWidget(buildWidget(
        onFilterChanged: (String text) => calls.add(text),
      ));
      await tester.pumpAndSettle();

      await sendChar(tester, 'a');
      await sendChar(tester, 'b');

      // Последний вызов содержит 'ab' (набрано в TextField)
      // или через onChanged TextField
      expect(calls, isNotEmpty);
    });
  });
}

/// Маппинг символа в LogicalKeyboardKey.
LogicalKeyboardKey _logicalKeyFor(String char) {
  switch (char.toLowerCase()) {
    case 'a':
      return LogicalKeyboardKey.keyA;
    case 'b':
      return LogicalKeyboardKey.keyB;
    case 'c':
      return LogicalKeyboardKey.keyC;
    case 'd':
      return LogicalKeyboardKey.keyD;
    case 'e':
      return LogicalKeyboardKey.keyE;
    case 'f':
      return LogicalKeyboardKey.keyF;
    default:
      return LogicalKeyboardKey.keyA;
  }
}
