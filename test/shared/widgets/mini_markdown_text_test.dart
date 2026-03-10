// Тесты для MiniMarkdownText.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xerabora/shared/theme/app_colors.dart';
import 'package:xerabora/shared/theme/app_typography.dart';
import 'package:xerabora/shared/widgets/mini_markdown_text.dart';

void main() {
  Widget buildWidget({
    required String text,
    TextStyle? style,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MiniMarkdownText(
          text: text,
          style: style,
        ),
      ),
    );
  }

  /// Извлекает [TextSpan] из виджета [Text.rich] найденного в дереве.
  TextSpan findRootTextSpan(WidgetTester tester) {
    final RichText richText = tester.widget<RichText>(
      find.byType(RichText).first,
    );
    return richText.text as TextSpan;
  }

  /// Находит [TextSpan] по тексту в дереве span-ов.
  TextSpan? findSpanByText(TextSpan root, String text) {
    if (root.text == text) return root;
    if (root.children == null) return null;
    for (final InlineSpan child in root.children!) {
      if (child is TextSpan) {
        final TextSpan? found = findSpanByText(child, text);
        if (found != null) return found;
      }
    }
    return null;
  }

  group('MiniMarkdownText', () {
    group('plain text', () {
      testWidgets('должен рендерить обычный текст как есть',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: 'Hello world'));
        await tester.pumpAndSettle();

        expect(find.byType(MiniMarkdownText), findsOneWidget);

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'Hello world');
        expect(span, isNotNull);
      });

      testWidgets('должен использовать кастомный стиль',
          (WidgetTester tester) async {
        const TextStyle customStyle = TextStyle(
          fontSize: 20,
          color: Colors.red,
        );
        await tester.pumpWidget(buildWidget(
          text: 'Styled',
          style: customStyle,
        ));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'Styled');
        expect(span, isNotNull);
        expect(span!.style?.fontSize, 20);
        expect(span.style?.color, Colors.red);
      });

      testWidgets('должен использовать AppTypography.body по умолчанию',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: 'Default'));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'Default');
        expect(span, isNotNull);
        expect(span!.style?.fontSize, AppTypography.body.fontSize);
      });
    });

    group('**bold**', () {
      testWidgets('должен рендерить жирный текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: '**bold**'));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'bold');
        expect(span, isNotNull);
        expect(span!.style?.fontWeight, FontWeight.w700);
      });

      testWidgets('не должен показывать маркеры **',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: '**bold**'));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        expect(findSpanByText(root, '**bold**'), isNull);
        expect(findSpanByText(root, '**'), isNull);
      });
    });

    group('*italic*', () {
      testWidgets('должен рендерить курсивный текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: '*italic*'));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'italic');
        expect(span, isNotNull);
        expect(span!.style?.fontStyle, FontStyle.italic);
      });
    });

    group('[text](url)', () {
      testWidgets('должен рендерить ссылку с brand цветом',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: '[Guide](https://example.com)'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'Guide');
        expect(span, isNotNull);
        expect(span!.style?.color, AppColors.brand);
        expect(span.style?.decoration, TextDecoration.underline);
      });

      testWidgets('должен иметь TapGestureRecognizer',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: '[Link](https://example.com)'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'Link');
        expect(span, isNotNull);
        expect(span!.recognizer, isA<TapGestureRecognizer>());
      });

      testWidgets('должен рендерить ссылку с произвольным URL',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: '[guide](topper)'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'guide');
        expect(span, isNotNull);
        expect(span!.style?.color, AppColors.brand);
        expect(span.style?.decoration, TextDecoration.underline);
        expect(span.recognizer, isA<TapGestureRecognizer>());
      });

      testWidgets('не должен показывать синтаксис ссылки',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: '[text](https://url.com)'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        expect(findSpanByText(root, '[text](https://url.com)'), isNull);
        expect(findSpanByText(root, 'text'), isNotNull);
      });
    });

    group('bare URL', () {
      testWidgets('должен рендерить голый URL как ссылку',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'Visit https://example.com today'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? urlSpan =
            findSpanByText(root, 'https://example.com');
        expect(urlSpan, isNotNull);
        expect(urlSpan!.style?.color, AppColors.brand);
        expect(urlSpan.recognizer, isA<TapGestureRecognizer>());
      });
    });

    group('mixed content', () {
      testWidgets('должен рендерить смешанный текст',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(
          text: 'This is **bold** and *italic* and '
              '[link](https://x.com)',
        ));
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);

        // Обычный текст
        expect(findSpanByText(root, 'This is '), isNotNull);
        expect(findSpanByText(root, ' and '), isNotNull);

        // Bold
        final TextSpan? boldSpan = findSpanByText(root, 'bold');
        expect(boldSpan, isNotNull);
        expect(boldSpan!.style?.fontWeight, FontWeight.w700);

        // Italic
        final TextSpan? italicSpan = findSpanByText(root, 'italic');
        expect(italicSpan, isNotNull);
        expect(italicSpan!.style?.fontStyle, FontStyle.italic);

        // Link
        final TextSpan? linkSpan = findSpanByText(root, 'link');
        expect(linkSpan, isNotNull);
        expect(linkSpan!.style?.color, AppColors.brand);
      });
    });

    group('empty / no markdown', () {
      testWidgets('должен рендерить пустую строку',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: ''));
        await tester.pumpAndSettle();

        expect(find.byType(MiniMarkdownText), findsOneWidget);
      });

      testWidgets('должен рендерить текст без разметки',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          buildWidget(text: 'No markdown here'),
        );
        await tester.pumpAndSettle();

        final TextSpan root = findRootTextSpan(tester);
        final TextSpan? span = findSpanByText(root, 'No markdown here');
        expect(span, isNotNull);
        expect(span!.style?.fontWeight, isNot(FontWeight.w700));
        expect(span.style?.fontStyle, isNot(FontStyle.italic));
      });
    });

    group('widget update', () {
      testWidgets('должен обновить span-ы при изменении text',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget(text: '**old**'));
        await tester.pumpAndSettle();

        TextSpan root = findRootTextSpan(tester);
        expect(findSpanByText(root, 'old'), isNotNull);
        expect(findSpanByText(root, 'old')!.style?.fontWeight, FontWeight.w700);

        await tester.pumpWidget(buildWidget(text: '*new*'));
        await tester.pumpAndSettle();

        root = findRootTextSpan(tester);
        expect(findSpanByText(root, 'new'), isNotNull);
        expect(
          findSpanByText(root, 'new')!.style?.fontStyle,
          FontStyle.italic,
        );
      });
    });
  });
}
