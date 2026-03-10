// Виджет для отображения текста с мини-markdown разметкой.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Виджет для отображения текста с поддержкой мини-markdown.
///
/// Поддерживаемый синтаксис:
/// - `**жирный**` → bold
/// - `*курсив*` → italic
/// - `[текст](url)` → кликабельная ссылка
/// - `https://...` → auto-linkify
class MiniMarkdownText extends StatefulWidget {
  /// Создаёт [MiniMarkdownText].
  const MiniMarkdownText({
    required this.text,
    this.style,
    super.key,
  });

  /// Исходный текст с markdown-разметкой.
  final String text;

  /// Базовый стиль текста.
  final TextStyle? style;

  @override
  State<MiniMarkdownText> createState() => _MiniMarkdownTextState();
}

class _MiniMarkdownTextState extends State<MiniMarkdownText> {
  final List<TapGestureRecognizer> _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(MiniMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      for (final TapGestureRecognizer recognizer in _recognizers) {
        recognizer.dispose();
      }
      _recognizers.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      _parse(widget.text, widget.style ?? AppTypography.body),
    );
  }

  /// Регулярное выражение для поиска markdown-элементов.
  static final RegExp _pattern = RegExp(
    r'\*\*(.+?)\*\*'
    r'|\*(.+?)\*'
    r'|\[([^\]]+)\]\((https?://[^\)]+)\)'
    r'|(https?://\S+)',
  );

  TextSpan _parse(String input, TextStyle baseStyle) {
    // Очищаем старые recognizers при пересборке.
    for (final TapGestureRecognizer recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final List<InlineSpan> children = <InlineSpan>[];
    int lastEnd = 0;

    for (final RegExpMatch match in _pattern.allMatches(input)) {
      if (match.start > lastEnd) {
        children.add(TextSpan(
          text: input.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        children.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        children.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(3) != null && match.group(4) != null) {
        // [text](url)
        children.add(_buildLink(match.group(3)!, match.group(4)!, baseStyle));
      } else if (match.group(5) != null) {
        // bare URL
        final String url = match.group(5)!;
        children.add(_buildLink(url, url, baseStyle));
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      children.add(TextSpan(
        text: input.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children);
  }

  TextSpan _buildLink(String text, String url, TextStyle baseStyle) {
    final TapGestureRecognizer recognizer = TapGestureRecognizer()
      ..onTap = () => _launchUrl(url);
    _recognizers.add(recognizer);

    return TextSpan(
      text: text,
      style: baseStyle.copyWith(
        color: AppColors.brand,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.brand,
      ),
      recognizer: recognizer,
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
