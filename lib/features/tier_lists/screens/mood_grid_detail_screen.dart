import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/models/mood_grid_cell.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/mood_grid_detail_provider.dart';
import '../providers/mood_grids_provider.dart';
import '../widgets/mood_grid_export_view.dart';
import '../widgets/mood_grid_item_picker.dart';
import '../widgets/mood_grid_view.dart';

/// Detail screen for a single mood grid.
class MoodGridDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [MoodGridDetailScreen].
  const MoodGridDetailScreen({required this.gridId, super.key});

  /// Grid id.
  final int gridId;

  @override
  ConsumerState<MoodGridDetailScreen> createState() =>
      _MoodGridDetailScreenState();
}

class _MoodGridDetailScreenState extends ConsumerState<MoodGridDetailScreen> {
  final GlobalKey _exportKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<MoodGridDetailState> async =
        ref.watch(moodGridDetailProvider(widget.gridId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object e, StackTrace s) =>
          Center(child: Text(l.errorPrefix(e.toString()))),
      data: (MoodGridDetailState state) {
        final String authorName =
            ref.watch(settingsNotifierProvider).authorName;
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
                        onCellTap: (MoodGridCell c) => _pickItem(c),
                        onCellContextMenu:
                            (MoodGridCell c, Offset pos) =>
                                _showCellContextMenu(c, pos, l),
                      ),
                      Positioned(
                        left: -10000,
                        top: -10000,
                        child: MoodGridExportView(
                          repaintKey: _exportKey,
                          grid: state.grid,
                          cells: state.cells,
                          authorName: authorName,
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
                label: l.moodGridExportImage,
                onTap: () => _exportAsImage(state.grid.name, l),
              ),
              items: <DraggableFabItem>[
                DraggableFabItem(
                  icon: Icons.text_fields,
                  label: l.moodGridRename,
                  onTap: () => _renameGrid(state.grid.name, l),
                ),
                const DraggableFabDivider(),
                DraggableFabItem(
                  icon: Icons.delete_outline,
                  label: l.moodGridDelete,
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Center(
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _Stepper(
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
            ),
            _Stepper(
              label: l.moodGridCols,
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
            ),
          ],
        ),
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
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l.moodGridShrinkTitle),
          content: Text(l.moodGridShrinkMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l.moodGridShrinkConfirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    await ref
        .read(moodGridDetailProvider(widget.gridId).notifier)
        .resize(newRows: newRows, newCols: newCols);
  }

  Future<void> _showCellContextMenu(
    MoodGridCell cell,
    Offset pos,
    S l,
  ) async {
    if (cell.id < 0) return;
    final RelativeRect position =
        RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy);
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
              leading: const Icon(Icons.clear, color: AppColors.error),
              title: Text(
                l.moodGridClearItem,
                style: const TextStyle(color: AppColors.error),
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
    final TextEditingController controller =
        TextEditingController(text: cell.label ?? '');
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
  }

  Future<void> _pickItem(MoodGridCell cell) async {
    if (cell.id < 0) return;
    final MoodGridItemPickerResult? result =
        await showMoodGridItemPicker(context);
    if (result == null) return;
    final CollectionItem item = result.item;
    await ref
        .read(moodGridDetailProvider(widget.gridId).notifier)
        .setCellItem(
          cellId: cell.id,
          mediaType: item.mediaType,
          externalId: item.externalId,
          platformId: item.platformId,
        );
  }

  Future<void> _renameGrid(String current, S l) async {
    final TextEditingController controller =
        TextEditingController(text: current);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.moodGridRename),
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
  }

  Future<void> _confirmDelete(S l) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.moodGridDeleteTitle),
        content: Text(l.moodGridDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.moodGridDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(moodGridsProvider.notifier).delete(widget.gridId);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _exportAsImage(String gridName, S l) async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final RenderRepaintBoundary? boundary = _exportKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Windows forbids <>:"/\|?* in file names; sanitize before the picker.
      final String safeName =
          gridName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      final String fileName = safeName.isEmpty
          ? 'mood_grid_${widget.gridId}.png'
          : '$safeName.png';

      final bool mobile = Platform.isAndroid || Platform.isIOS;
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: l.moodGridExportImage,
        fileName: fileName,
        // On Android FileType.custom blocks the picker; FileType.any opens SAF.
        type: mobile ? FileType.any : FileType.custom,
        allowedExtensions: mobile ? null : <String>['png'],
        // bytes are required on Android — file_picker writes via SAF itself.
        bytes: mobile ? pngBytes : null,
      );
      if (outputPath == null) return;

      // Desktop: file_picker only returns the chosen path; we write the bytes
      // ourselves. Force a .png extension if the user removed it.
      if (!mobile) {
        final String finalPath = outputPath.toLowerCase().endsWith('.png')
            ? outputPath
            : '$outputPath.png';
        await File(finalPath).writeAsBytes(pngBytes);
      }

      if (!mounted) return;
      context.showSnack(l.moodGridImageSaved, type: SnackType.success);
    } on Exception catch (e) {
      if (!mounted) return;
      context.showSnack(l.errorPrefix(e.toString()), type: SnackType.error);
    }
  }
}

/// Compact label + value + step buttons. Keeps the resize toolbar narrow.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

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
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(label, style: AppTypography.bodySmall),
          ),
          _StepIcon(
            icon: Icons.remove,
            onPressed: onDecrement,
          ),
          SizedBox(
            width: 28,
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ),
          _StepIcon(
            icon: Icons.add,
            onPressed: onIncrement,
          ),
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
