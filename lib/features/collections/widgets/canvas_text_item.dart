import 'package:core/models/canvas_item.dart';
import 'package:flutter/material.dart';

/// Data lives in CanvasItem.data: {content: String, fontSize: double}.
class CanvasTextItem extends StatelessWidget {
  const CanvasTextItem({required this.item, super.key});

  final CanvasItem item;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = item.data;
    final String content =
        data?['content'] as String? ?? '';
    final double fontSize =
        (data?['fontSize'] as num?)?.toDouble() ?? 16;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        content,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
        ),
        overflow: TextOverflow.clip,
      ),
    );
  }
}
