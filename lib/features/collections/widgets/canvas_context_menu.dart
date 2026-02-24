import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/canvas_item.dart';

// Контекстные меню для канваса.
//
// Статические методы для отображения контекстного меню пустого места
// канваса и контекстного меню элемента.

/// Утилитарный класс для контекстных меню канваса.
class CanvasContextMenu {
  CanvasContextMenu._();

  /// Отображает контекстное меню пустого места на канвасе.
  ///
  /// [position] — экранные координаты клика ПКМ.
  /// Колбэки вызываются при выборе соответствующего пункта.
  static Future<void> showCanvasMenu(
    BuildContext context, {
    required Offset position,
    required VoidCallback onAddText,
    required VoidCallback onAddImage,
    required VoidCallback onAddLink,
    VoidCallback? onFindImages,
    VoidCallback? onBrowseMaps,
  }) async {
    final S l = S.of(context);
    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'add_text',
          child: Row(
            children: <Widget>[
              const Icon(Icons.text_fields, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasAddText),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_image',
          child: Row(
            children: <Widget>[
              const Icon(Icons.image_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasAddImage),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'add_link',
          child: Row(
            children: <Widget>[
              const Icon(Icons.link, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasAddLink),
            ],
          ),
        ),
        if (onFindImages != null || onBrowseMaps != null) ...<PopupMenuEntry<String>>[
          const PopupMenuDivider(),
          if (onFindImages != null)
            PopupMenuItem<String>(
              value: 'find_images',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.image_search, size: 20),
                  const SizedBox(width: 12),
                  Text(l.canvasFindImages),
                ],
              ),
            ),
          if (onBrowseMaps != null)
            PopupMenuItem<String>(
              value: 'browse_maps',
              child: Row(
                children: <Widget>[
                  const Icon(Icons.map, size: 20),
                  const SizedBox(width: 12),
                  Text(l.canvasBrowseMaps),
                ],
              ),
            ),
        ],
      ],
    );

    if (value == null) return;
    switch (value) {
      case 'add_text':
        onAddText();
      case 'add_image':
        onAddImage();
      case 'add_link':
        onAddLink();
      case 'find_images':
        onFindImages?.call();
      case 'browse_maps':
        onBrowseMaps?.call();
    }
  }

  /// Отображает контекстное меню элемента канваса.
  ///
  /// [itemType] определяет, показывать ли пункт Edit.
  /// Edit доступен для text, image и link (но не для game).
  static Future<void> showItemMenu(
    BuildContext context, {
    required Offset position,
    required CanvasItemType itemType,
    VoidCallback? onEdit,
    required VoidCallback onDelete,
    required VoidCallback onBringToFront,
    required VoidCallback onSendToBack,
    VoidCallback? onConnect,
  }) async {
    final bool showEdit = !itemType.isMediaItem;
    final S l = S.of(context);

    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        if (showEdit)
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: 12),
                Text(l.edit),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: <Widget>[
              const Icon(Icons.delete_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l.delete),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'connect',
          child: Row(
            children: <Widget>[
              const Icon(Icons.timeline, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasConnect),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'bring_to_front',
          child: Row(
            children: <Widget>[
              const Icon(Icons.flip_to_front, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasBringToFront),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'send_to_back',
          child: Row(
            children: <Widget>[
              const Icon(Icons.flip_to_back, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasSendToBack),
            ],
          ),
        ),
      ],
    );

    if (value == null) return;
    switch (value) {
      case 'edit':
        onEdit?.call();
      case 'delete':
        if (!context.mounted) return;
        _showDeleteConfirmation(context, onDelete);
      case 'connect':
        onConnect?.call();
      case 'bring_to_front':
        onBringToFront();
      case 'send_to_back':
        onSendToBack();
    }
  }

  /// Отображает контекстное меню связи.
  static Future<void> showConnectionMenu(
    BuildContext context, {
    required Offset position,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) async {
    final S l = S.of(context);
    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: <Widget>[
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasEditConnection),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: <Widget>[
              const Icon(Icons.delete_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l.canvasDeleteConnection),
            ],
          ),
        ),
      ],
    );

    if (value == null) return;
    switch (value) {
      case 'edit':
        onEdit();
      case 'delete':
        if (!context.mounted) return;
        _showDeleteConfirmation(context, onDelete);
    }
  }

  /// Показывает диалог подтверждения удаления.
  static Future<void> _showDeleteConfirmation(
    BuildContext context,
    VoidCallback onConfirm,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final S dl = S.of(context);
        return AlertDialog(
          scrollable: true,
          title: Text(dl.canvasDeleteElement),
          content: Text(dl.canvasDeleteElementMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(dl.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(dl.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      onConfirm();
    }
  }
}
