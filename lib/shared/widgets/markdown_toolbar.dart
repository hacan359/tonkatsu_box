// Тулбар для мини-markdown разметки (bold, italic, link).

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Тулбар с кнопками Bold / Italic / Link для markdown-разметки.
///
/// Используется совместно с [TextEditingController] для вставки
/// маркеров в текстовое поле.
class MarkdownToolbar extends StatelessWidget {
  /// Создаёт [MarkdownToolbar].
  const MarkdownToolbar({
    required this.controller,
    super.key,
  });

  /// Контроллер текстового поля, в которое вставляются маркеры.
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _MarkdownToolbarButton(
          icon: Icons.format_bold,
          tooltip: S.of(context).markdownBold,
          onPressed: () => wrapSelection(controller, '**'),
        ),
        _MarkdownToolbarButton(
          icon: Icons.format_italic,
          tooltip: S.of(context).markdownItalic,
          onPressed: () => wrapSelection(controller, '*'),
        ),
        _MarkdownToolbarButton(
          icon: Icons.link,
          tooltip: S.of(context).insertLink,
          onPressed: () => insertLink(context, controller),
        ),
      ],
    );
  }

  /// Оборачивает выделенный текст (или вставляет пустые маркеры) в [marker].
  static void wrapSelection(
    TextEditingController controller,
    String marker,
  ) {
    final TextSelection selection = controller.selection;
    final String text = controller.text;

    if (!selection.isValid) return;

    if (selection.isCollapsed) {
      final int pos = selection.baseOffset;
      controller.text =
          '${text.substring(0, pos)}$marker$marker${text.substring(pos)}';
      controller.selection =
          TextSelection.collapsed(offset: pos + marker.length);
    } else {
      final String selected =
          text.substring(selection.start, selection.end);
      controller.text =
          '${text.substring(0, selection.start)}$marker$selected$marker${text.substring(selection.end)}';
      controller.selection = TextSelection(
        baseOffset: selection.start + marker.length,
        extentOffset: selection.end + marker.length,
      );
    }
  }

  /// Открывает диалог вставки ссылки `[text](url)`.
  static Future<void> insertLink(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final TextEditingController textCtrl = TextEditingController();
    final TextEditingController urlCtrl = TextEditingController();

    final TextSelection selection = controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      textCtrl.text =
          controller.text.substring(selection.start, selection.end);
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(S.of(ctx).insertLink),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: textCtrl,
                decoration: InputDecoration(
                  labelText: S.of(ctx).linkText,
                  hintText: S.of(ctx).linkHint,
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  labelText: S.of(ctx).urlLabel,
                  hintText: S.of(ctx).urlHint,
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(S.of(ctx).insert),
          ),
        ],
      ),
    );

    if (confirmed != true || urlCtrl.text.isEmpty) return;

    final String linkText =
        textCtrl.text.isNotEmpty ? textCtrl.text : urlCtrl.text;
    final String markdown = '[$linkText](${urlCtrl.text})';

    final int start = selection.isValid && !selection.isCollapsed
        ? selection.start
        : (selection.isValid ? selection.baseOffset : controller.text.length);
    final int end = selection.isValid && !selection.isCollapsed
        ? selection.end
        : start;

    controller.text =
        '${controller.text.substring(0, start)}$markdown${controller.text.substring(end)}';
    controller.selection =
        TextSelection.collapsed(offset: start + markdown.length);
  }
}

/// Кнопка мини-тулбара для markdown-разметки.
class _MarkdownToolbarButton extends StatelessWidget {
  const _MarkdownToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      tooltip: tooltip,
      color: AppColors.textSecondary,
    );
  }
}
