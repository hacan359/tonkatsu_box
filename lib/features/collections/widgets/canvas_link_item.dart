import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/models/canvas_item.dart';

// Виджет ссылки на канвасе.
//
// Отображает карточку с иконкой ссылки и текстом.
// Данные хранятся в CanvasItem.data: {url: String, label: String}.

/// Ссылка на канвасе.
class CanvasLinkItem extends StatelessWidget {
  /// Создаёт [CanvasLinkItem].
  const CanvasLinkItem({required this.item, super.key});

  /// Элемент канваса с данными ссылки.
  final CanvasItem item;

  Future<void> _openUrl() async {
    final String? url = item.data?['url'] as String?;
    if (url == null || url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? data = item.data;
    final String label = data?['label'] as String? ??
        data?['url'] as String? ??
        'Link';
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return GestureDetector(
      onDoubleTap: _openUrl,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.link,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
