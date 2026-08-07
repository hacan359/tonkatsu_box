import 'package:core/models/collection_item.dart';
import 'package:core/models/mood_grid_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/services/png_export_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../providers/mood_grid_detail_provider.dart';
import '../providers/mood_grid_picker_session_provider.dart';
import '../providers/mood_grids_provider.dart';
import '../services/mood_grid_caption.dart';
import '../widgets/mood_grid_export_view.dart';
import '../widgets/mood_grid_item_picker.dart';
import '../widgets/mood_grid_view.dart';

/// Detail screen for a single mood grid.
class MoodGridDetailScreen extends ConsumerStatefulWidget {
  const MoodGridDetailScreen({required this.gridId, super.key});

  final int gridId;

  @override
  ConsumerState<MoodGridDetailScreen> createState() =>
      _MoodGridDetailScreenState();
}

class _MoodGridDetailScreenState extends ConsumerState<MoodGridDetailScreen> {
  final GlobalKey _exportKey = GlobalKey();

  static const double _defaultCellWidth = 140;
  static const double _minCellWidth = 80;
  static const double _maxCellWidth = 240;
  static const double _cellWidthStep = 20;

  /// Screen-only cell width; intentionally not persisted — reopening the
  /// grid resets it to the default.
  double _cellWidth = _defaultCellWidth;

  /// Mounts the offscreen export view only while an export is running, so
  /// the duplicate cell tree doesn't cost layout/paint the rest of the time.
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    // Pins the picker session (filter + search + item cache) to this
    // screen's lifetime: it survives picker reopenings and resets on leave.
    ref.listenManual(
      moodGridPickerSessionProvider,
      (MoodGridPickerSession? previous, MoodGridPickerSession next) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<MoodGridDetailState> async = ref.watch(
      moodGridDetailProvider(widget.gridId),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace s) =>
          Center(child: Text(l.errorPrefix(e.toString()))),
      data: (MoodGridDetailState state) {
        return Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                SubScreenTitleBar(title: state.grid.name),
                _buildResizeControls(state, l),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      MoodGridView(
                        grid: state.grid,
                        cells: state.cells,
                        mediaByPosition: state.mediaByPosition,
                        cellWidth: _cellWidth,
                        onCellTap: (MoodGridCell c) => _pickItem(c),
                        onCellLabelTap: (MoodGridCell c) => _editLabel(c, l),
                        onCellContextMenu: (MoodGridCell c, Offset pos) =>
                            _showCellContextMenu(c, pos, l),
                      ),
                      if (_exporting)
                        Positioned(
                          left: -10000,
                          top: -10000,
                          child: MoodGridExportView(
                            repaintKey: _exportKey,
                            grid: state.grid,
                            cells: state.cells,
                            mediaByPosition: state.mediaByPosition,
                            cellWidth: _cellWidth,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            DraggableFab(
              mainAction: DraggableFabItem(
                icon: Icons.image_outlined,
                label: l.exportAsImage,
                onTap: () => _exportAsImage(state.grid.name, l),
              ),
              items: <DraggableFabItem>[
                DraggableFabItem(
                  icon: Icons.text_fields,
                  label: l.rename,
                  onTap: () => _renameGrid(state.grid.name, l),
                ),
                DraggableFabItem(
                  icon: Icons.view_column_outlined,
                  label: l.moodGridCaptionTemplate,
                  onTap: () => _editTemplate(
                    title: l.moodGridCaptionTemplate,
                    current: state.grid.captionTemplate,
                    save: ref
                        .read(moodGridDetailProvider(widget.gridId).notifier)
                        .setCaptionTemplate,
                    l: l,
                  ),
                ),
                DraggableFabItem(
                  icon: Icons.label_outline,
                  label: l.moodGridCellLabelTemplate,
                  onTap: () => _editTemplate(
                    title: l.moodGridCellLabelTemplate,
                    current: state.grid.cellLabelTemplate,
                    save: ref
                        .read(moodGridDetailProvider(widget.gridId).notifier)
                        .setCellLabelTemplate,
                    l: l,
                  ),
                ),
                const DraggableFabDivider(),
                DraggableFabItem(
                  icon: Icons.delete_outline,
                  label: l.delete,
                  iconColor: AppColors.error,
                  onTap: () => _confirmDelete(l),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildResizeControls(MoodGridDetailState state, S l) {
    final _Stepper rows = _Stepper(
      label: l.moodGridRows,
      value: state.grid.rows,
      onDecrement: state.grid.rows <= 1
          ? null
          : () => _resize(
              newRows: state.grid.rows - 1,
              newCols: state.grid.cols,
              state: state,
              l: l,
            ),
      onIncrement: () => _resize(
        newRows: state.grid.rows + 1,
        newCols: state.grid.cols,
        state: state,
        l: l,
      ),
    );
    final _Stepper cols = _Stepper(
      label: l.columnsCount,
      value: state.grid.cols,
      onDecrement: state.grid.cols <= 1
          ? null
          : () => _resize(
              newRows: state.grid.rows,
              newCols: state.grid.cols - 1,
              state: state,
              l: l,
            ),
      onIncrement: () => _resize(
        newRows: state.grid.rows,
        newCols: state.grid.cols + 1,
        state: state,
        l: l,
      ),
    );
    final _Stepper size = _Stepper(
      label: l.moodGridCellSize,
      value: _cellWidth.round(),
      onDecrement: _cellWidth <= _minCellWidth
          ? null
          : () => setState(() => _cellWidth = _cellWidth - _cellWidthStep),
      onIncrement: _cellWidth >= _maxCellWidth
          ? null
          : () => setState(() => _cellWidth = _cellWidth + _cellWidthStep),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Wide: one intrinsic-width line. Narrow: two rows of stretched,
          // equal-width steppers so the controls line up.
          if (constraints.maxWidth >= 480) {
            return Center(
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: <Widget>[rows, cols, size],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(child: rows.stretched()),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: cols.stretched()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              size.stretched(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _resize({
    required int newRows,
    required int newCols,
    required MoodGridDetailState state,
    required S l,
  }) async {
    final bool shrinking =
        newRows < state.grid.rows || newCols < state.grid.cols;
    if (shrinking) {
      final bool ok = await ConfirmDialog.show(
        context,
        title: l.moodGridShrinkTitle,
        message: l.moodGridShrinkMessage,
        confirmLabel: l.moodGridShrinkConfirm,
      );
      if (!ok) return;
    }

    await ref
        .read(moodGridDetailProvider(widget.gridId).notifier)
        .resize(newRows: newRows, newCols: newCols);
  }

  Future<void> _showCellContextMenu(MoodGridCell cell, Offset pos, S l) async {
    if (cell.id < 0) return;
    final RelativeRect position = RelativeRect.fromLTRB(
      pos.dx,
      pos.dy,
      pos.dx,
      pos.dy,
    );
    final String? action = await showMenu<String>(
      context: context,
      position: position,
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'label',
          child: ListTile(
            leading: const Icon(Icons.text_fields),
            title: Text(l.moodGridEditLabel),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem<String>(
          value: 'pick',
          child: ListTile(
            leading: const Icon(Icons.image_search),
            title: Text(
              cell.isEmpty ? l.moodGridPickItem : l.moodGridReplaceItem,
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (!cell.isEmpty)
          PopupMenuItem<String>(
            value: 'clear',
            child: ListTile(
              leading: Icon(Icons.clear, color: AppColors.error),
              title: Text(
                l.moodGridClearItem,
                style: TextStyle(color: AppColors.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'label':
        await _editLabel(cell, l);
      case 'pick':
        await _pickItem(cell);
      case 'clear':
        await ref
            .read(moodGridDetailProvider(widget.gridId).notifier)
            .clearCellItem(cell.id);
    }
  }

  Future<void> _editLabel(MoodGridCell cell, S l) async {
    if (cell.id < 0) return;
    final TextEditingController controller = TextEditingController(
      text: cell.label ?? '',
    );
    try {
      final String? newLabel = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.moodGridEditLabel),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l.moodGridLabelHint),
            onSubmitted: (String v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (newLabel == null) return;
      final String? normalized = newLabel.isEmpty ? null : newLabel;
      await ref
          .read(moodGridDetailProvider(widget.gridId).notifier)
          .setCellLabel(cell.id, normalized);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _pickItem(MoodGridCell cell) async {
    if (cell.id < 0) return;
    final MoodGridItemPickerResult? result = await showMoodGridItemPicker(
      context,
    );
    if (result == null) return;
    final CollectionItem item = result.item;
    await ref
        .read(moodGridDetailProvider(widget.gridId).notifier)
        .setCellItem(
          cellId: cell.id,
          mediaType: item.mediaType,
          externalId: item.externalId,
          platformId: item.platformId,
          source: item.source,
        );
  }

  Future<void> _renameGrid(String current, S l) async {
    final TextEditingController controller = TextEditingController(
      text: current,
    );
    try {
      final String? newName = await showDialog<String>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.rename),
          content: TextField(
            controller: controller,
            autofocus: true,
            onSubmitted: (String v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (newName == null || newName.isEmpty) return;
      await ref
          .read(moodGridDetailProvider(widget.gridId).notifier)
          .rename(newName);
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmDelete(S l) async {
    final bool ok = await ConfirmDialog.show(
      context,
      title: l.moodGridDeleteTitle,
      message: l.moodGridDeleteMessage,
      confirmLabel: l.delete,
    );
    if (!ok) return;
    await ref.read(moodGridsProvider.notifier).delete(widget.gridId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _editTemplate({
    required String title,
    required String? current,
    required Future<void> Function(String) save,
    required S l,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => _CaptionTemplateDialog(
        title: title,
        initial: current ?? '{{name}}',
        l: l,
      ),
    );
    if (result == null) return;
    await save(result);
  }

  Future<void> _exportAsImage(String gridName, S l) async {
    setState(() => _exporting = true);
    try {
      // Mount frame + a beat for CachedImage file lookups, then the repaint
      // frame — so covers land in the capture.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      final String safeName = sanitizeFileName(gridName);
      final String fileName =
          '${safeName.isEmpty ? 'mood_grid_${widget.gridId}' : safeName}.png';

      final BulkExportResult result = await saveBoundaryAsPng(
        repaintKey: _exportKey,
        suggestedFileName: fileName,
        saveDialogTitle: l.exportAsImage,
      );
      if (!mounted) return;

      switch (result.status) {
        case BulkExportStatus.saved:
          context.showSnack(l.imageSaved, type: SnackType.success);
        case BulkExportStatus.cancelled:
          break;
        case BulkExportStatus.failed:
          context.showSnack(
            l.errorPrefix(result.error?.toString() ?? ''),
            type: SnackType.error,
          );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

/// Compact label + value + step buttons. Intrinsic width by default;
/// [stretched] fills the parent with the label left and controls right.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.stretch = false,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool stretch;

  _Stepper stretched() => _Stepper(
        label: label,
        value: value,
        onDecrement: onDecrement,
        onIncrement: onIncrement,
        stretch: true,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          // Flexible needs bounded width; in the intrinsic (Wrap) case the
          // Row is width-unbounded, so the label stays a plain child there.
          if (stretch)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(label, style: AppTypography.bodySmall),
            ),
          _StepIcon(icon: Icons.remove, onPressed: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ),
          _StepIcon(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _CaptionTemplateDialog extends StatefulWidget {
  const _CaptionTemplateDialog({
    required this.title,
    required this.initial,
    required this.l,
  });

  final String title;
  final String initial;
  final S l;

  @override
  State<_CaptionTemplateDialog> createState() => _CaptionTemplateDialogState();
}

class _CaptionTemplateDialogState extends State<_CaptionTemplateDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final TextSelection sel = _controller.selection;
    final String text = _controller.text;
    final String insert = '{{$token}}';
    final int start = sel.isValid ? sel.start : text.length;
    final int end = sel.isValid ? sel.end : text.length;
    final String next = text.replaceRange(start, end, insert);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final S l = widget.l;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        // Scrollable: on phones the on-screen keyboard can squeeze the dialog
        // to ~150px of height.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l.moodGridCaptionTemplateHint,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  for (final String token in kMoodGridCaptionTokens)
                    ActionChip(
                      label: Text('{{$token}}'),
                      onPressed: () => _insertToken(token),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: Text(l.clear),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}
