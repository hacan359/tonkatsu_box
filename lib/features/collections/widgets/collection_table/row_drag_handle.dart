import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../shared/theme/app_spacing.dart';

/// trina_grid's built-in handle loses the gesture arena to grid scroll on
/// touch, so touch drags start from a hold; desktop keeps immediate drag.
class RowDragHandle extends StatelessWidget {
  const RowDragHandle({
    required this.row,
    required this.stateManager,
    super.key,
  });

  final TrinaRow<dynamic> row;
  final TrinaGridStateManager stateManager;

  /// Shorter than kLongPressTimeout so the hold wins the arena before the
  /// cell's own long-press (selection) recognizer fires at 500ms.
  static const Duration _touchHoldDelay = Duration(milliseconds: 300);

  static bool get _isTouchPlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.fuchsia;

  void _onDragStarted() {
    stateManager.setIsDraggingRow(true, notify: false);
    stateManager.setDragRows(<TrinaRow<dynamic>>[row]);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    stateManager.eventManager!.addEvent(
      TrinaGridScrollUpdateEvent(offset: details.globalPosition),
    );
    final int? targetIdx =
        stateManager.getRowIdxByOffset(details.globalPosition.dy);
    if (targetIdx != null) {
      stateManager.setDragTargetRowIdx(targetIdx);
    }
  }

  void _onDragEnd(DraggableDetails details) {
    stateManager.setIsDraggingRow(false);
    TrinaGridScrollUpdateEvent.stopScroll(
      stateManager,
      TrinaGridScrollUpdateDirection.all,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TrinaGridStyleConfig style = stateManager.configuration.style;
    // Fill the whole cell so the touch target is the full 48px column, not
    // just the icon glyph.
    final Widget handle = Container(
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Icon(
        Icons.drag_indicator,
        size: style.iconSize,
        color: style.iconColor,
      ),
    );
    final Widget feedback = FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: style.gridBackgroundColor,
            border: Border.all(color: style.activatedBorderColor),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            Icons.drag_indicator,
            size: style.iconSize,
            color: style.iconColor,
          ),
        ),
      ),
    );

    if (_isTouchPlatform) {
      return LongPressDraggable<TrinaRow<dynamic>>(
        data: row,
        delay: _touchHoldDelay,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        onDragStarted: _onDragStarted,
        onDragUpdate: _onDragUpdate,
        onDragEnd: _onDragEnd,
        child: handle,
      );
    }
    return Draggable<TrinaRow<dynamic>>(
      data: row,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: feedback,
      onDragStarted: _onDragStarted,
      onDragUpdate: _onDragUpdate,
      onDragEnd: _onDragEnd,
      child: handle,
    );
  }
}
