import 'package:flutter/material.dart';

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
    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'add_text',
          child: Row(
            children: <Widget>[
              Icon(Icons.text_fields, size: 20),
              SizedBox(width: 12),
              Text('Add Text'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_image',
          child: Row(
            children: <Widget>[
              Icon(Icons.image_outlined, size: 20),
              SizedBox(width: 12),
              Text('Add Image'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'add_link',
          child: Row(
            children: <Widget>[
              Icon(Icons.link, size: 20),
              SizedBox(width: 12),
              Text('Add Link'),
            ],
          ),
        ),
        if (onFindImages != null || onBrowseMaps != null) ...<PopupMenuEntry<String>>[
          const PopupMenuDivider(),
          if (onFindImages != null)
            const PopupMenuItem<String>(
              value: 'find_images',
              child: Row(
                children: <Widget>[
                  Icon(Icons.image_search, size: 20),
                  SizedBox(width: 12),
                  Text('Find images...'),
                ],
              ),
            ),
          if (onBrowseMaps != null)
            const PopupMenuItem<String>(
              value: 'browse_maps',
              child: Row(
                children: <Widget>[
                  Icon(Icons.map, size: 20),
                  SizedBox(width: 12),
                  Text('Browse maps...'),
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
    final bool showEdit = itemType != CanvasItemType.game;

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
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: <Widget>[
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: <Widget>[
              Icon(Icons.delete_outlined, size: 20),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'connect',
          child: Row(
            children: <Widget>[
              Icon(Icons.timeline, size: 20),
              SizedBox(width: 12),
              Text('Connect'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'bring_to_front',
          child: Row(
            children: <Widget>[
              Icon(Icons.flip_to_front, size: 20),
              SizedBox(width: 12),
              Text('Bring to Front'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'send_to_back',
          child: Row(
            children: <Widget>[
              Icon(Icons.flip_to_back, size: 20),
              SizedBox(width: 12),
              Text('Send to Back'),
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
    final String? value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: <Widget>[
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('Edit Connection'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: <Widget>[
              Icon(Icons.delete_outlined, size: 20),
              SizedBox(width: 12),
              Text('Delete Connection'),
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
        return AlertDialog(
          title: const Text('Delete element'),
          content: const Text(
            'Are you sure you want to delete this element?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
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
