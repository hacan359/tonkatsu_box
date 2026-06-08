import 'package:flutter/widgets.dart';

import '../providers/canvas_state.dart';
import '../../../shared/models/canvas_connection.dart';
import '../../../shared/models/canvas_item.dart';
import 'dialogs/add_image_dialog.dart';
import 'dialogs/add_link_dialog.dart';
import 'dialogs/add_text_dialog.dart';
import 'dialogs/edit_connection_dialog.dart';

/// Shows the canvas add/edit dialogs and forwards the result to the
/// controller. Lifted out of `_CanvasViewState` so the screen widget stays
/// focused on layout and gesture wiring.
///
/// Every entry point follows the same shape: show dialog → bail on null
/// or unmounted context → dispatch to [controller]. `context.mounted` is
/// rechecked after each `await` because dialogs may outlive the host
/// widget.
class CanvasItemActions {
  CanvasItemActions({
    required BuildContext context,
    required BaseCanvasController Function() controller,
  })  : _context = context,
        _controller = controller;

  final BuildContext _context;
  final BaseCanvasController Function() _controller;

  Future<void> addText(double x, double y) async {
    await _showAndApply(
      AddTextDialog.show(_context),
      (Map<String, dynamic> r) => _controller().addTextItem(
        x,
        y,
        r['content'] as String,
        (r['fontSize'] as num).toDouble(),
      ),
    );
  }

  Future<void> addImage(double x, double y) async {
    await _showAndApply(
      AddImageDialog.show(_context),
      (Map<String, dynamic> r) => _controller().addImageItem(x, y, r),
    );
  }

  Future<void> addLink(double x, double y) async {
    await _showAndApply(
      AddLinkDialog.show(_context),
      (Map<String, dynamic> r) => _controller().addLinkItem(
        x,
        y,
        r['url'] as String,
        r['label'] as String,
      ),
    );
  }

  /// Routes to the right edit dialog by item type; media-card items have
  /// no inline edit (their data lives in the upstream cache tables).
  Future<void> editItem(CanvasItem item) async {
    switch (item.itemType) {
      case CanvasItemType.text:
        await _showAndApply(
          AddTextDialog.show(
            _context,
            initialContent: item.data?['content'] as String?,
            initialFontSize: (item.data?['fontSize'] as num?)?.toDouble(),
          ),
          (Map<String, dynamic> r) =>
              _controller().updateItemData(item.id, r),
        );
      case CanvasItemType.image:
        await _showAndApply(
          AddImageDialog.show(
            _context,
            initialUrl: item.data?['url'] as String?,
          ),
          (Map<String, dynamic> r) =>
              _controller().updateItemData(item.id, r),
        );
      case CanvasItemType.link:
        await _showAndApply(
          AddLinkDialog.show(
            _context,
            initialUrl: item.data?['url'] as String?,
            initialLabel: item.data?['label'] as String?,
          ),
          (Map<String, dynamic> r) =>
              _controller().updateItemData(item.id, r),
        );
      case CanvasItemType.game:
      case CanvasItemType.movie:
      case CanvasItemType.tvShow:
      case CanvasItemType.animation:
      case CanvasItemType.visualNovel:
      case CanvasItemType.manga:
      case CanvasItemType.anime:
      case CanvasItemType.book:
      case CanvasItemType.custom:
        break;
    }
  }

  Future<void> editConnection(int connectionId, CanvasState canvasState) async {
    final CanvasConnection? conn = canvasState.connections
        .where((CanvasConnection c) => c.id == connectionId)
        .firstOrNull;
    if (conn == null) return;

    await _showAndApply(
      EditConnectionDialog.show(
        _context,
        initialLabel: conn.label,
        initialColor: conn.color,
        initialStyle: conn.style,
      ),
      (Map<String, dynamic> r) => _controller().updateConnection(
        connectionId,
        label: r['label'] as String?,
        color: r['color'] as String?,
        style: r['style'] != null
            ? ConnectionStyle.fromString(r['style'] as String)
            : null,
      ),
    );
  }

  Future<void> _showAndApply(
    Future<Map<String, dynamic>?> dialog,
    void Function(Map<String, dynamic>) apply,
  ) async {
    final Map<String, dynamic>? result = await dialog;
    if (result == null || !_context.mounted) return;
    apply(result);
  }
}
