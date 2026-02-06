import 'package:flutter/material.dart';

import '../../../shared/models/canvas_item.dart';

// Виджет текстового блока на канвасе.
//
// Отображает текст с настраиваемым размером шрифта.
// Данные хранятся в CanvasItem.data: {content: String, fontSize: double}.

/// Текстовый блок на канвасе.
class CanvasTextItem extends StatelessWidget {
  /// Создаёт [CanvasTextItem].
  const CanvasTextItem({required this.item, super.key});

  /// Элемент канваса с данными текста.
  final CanvasItem item;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = item.data;
    final String content =
        data?['content'] as String? ?? '';
    final double fontSize =
        (data?['fontSize'] as num?)?.toDouble() ?? 16;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          color: colorScheme.onSurface,
        ),
        overflow: TextOverflow.clip,
      ),
    );
  }
}
