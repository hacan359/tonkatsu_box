// Экран деталей одного тир-листа.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/keyboard/keyboard_shortcuts.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/auto_breadcrumb_app_bar.dart';
import '../../../shared/widgets/breadcrumb_scope.dart';
import '../../../shared/widgets/type_to_filter_overlay.dart';
import '../providers/tier_list_detail_provider.dart';
import '../widgets/tier_list_view.dart';
import '../widgets/tier_list_export_view.dart';

/// Экран одного тир-листа с drag-and-drop.
class TierListDetailScreen extends ConsumerStatefulWidget {
  /// Создаёт [TierListDetailScreen].
  const TierListDetailScreen({required this.tierListId, super.key});

  /// ID тир-листа.
  final int tierListId;

  /// Группа хоткеев этого экрана для легенды F1.
  static const ShortcutGroup shortcutGroup = ShortcutGroup(
    title: 'Тир-лист',
    entries: <ShortcutEntry>[
      ShortcutEntry(keys: 'Ctrl+E', description: 'Экспорт как изображение'),
      ShortcutEntry(keys: 'Ctrl+Enter', description: 'Добавить тир'),
      ShortcutEntry(keys: 'Ctrl+Shift+D', description: 'Очистить все'),
    ],
  );

  @override
  ConsumerState<TierListDetailScreen> createState() =>
      _TierListDetailScreenState();
}

class _TierListDetailScreenState
    extends ConsumerState<TierListDetailScreen> {
  final GlobalKey _exportKey = GlobalKey();
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final TierListDetailState state =
        ref.watch(tierListDetailProvider(widget.tierListId));

    return BreadcrumbScope(
      label: state.isLoading ? l.tierListTitle : state.tierList.name,
      child: CallbackShortcuts(
        bindings: _buildScreenShortcuts(state),
        child: Scaffold(
        appBar: AutoBreadcrumbAppBar(
          actions: <Widget>[
            if (!state.isLoading)
              IconButton(
                icon: const Icon(Icons.image_outlined),
                color: AppColors.textSecondary,
                tooltip: kIsMobile
                    ? l.tierListExportImage
                    : '${l.tierListExportImage} (Ctrl+E)',
                onPressed: () => _exportAsImage(context, state),
              ),
            if (!state.isLoading)
              PopupMenuButton<String>(
                iconColor: AppColors.textSecondary,
                onSelected: (String action) =>
                    _handleMenuAction(action, state),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'clear',
                    child: ListTile(
                      leading: const Icon(Icons.clear_all),
                      title: Text(l.tierListClearAll),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TypeToFilterOverlay(
                onFilterChanged: (String query) {
                  setState(() => _filterQuery = query);
                },
                child: Stack(
                  children: <Widget>[
                    TierListView(
                      tierListId: widget.tierListId,
                      state: state,
                      filterQuery: _filterQuery,
                    ),
                    // Off-screen export view — must be painted (not Offstage)
                    // for RepaintBoundary.toImage() to work.
                    Positioned(
                      left: -10000,
                      top: -10000,
                      child: SizedBox(
                        width: 800,
                        child: TierListExportView(
                          repaintKey: _exportKey,
                          state: state,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildScreenShortcuts(
    TierListDetailState state,
  ) {
    if (kIsMobile || state.isLoading) {
      return <ShortcutActivator, VoidCallback>{};
    }
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyE, control: true):
          () => _exportAsImage(context, state),
      const SingleActivator(LogicalKeyboardKey.enter, control: true):
          () => _addTier(context),
      const SingleActivator(
        LogicalKeyboardKey.keyD,
        control: true,
        shift: true,
      ): () => _confirmClear(context),
    };
  }

  void _handleMenuAction(String action, TierListDetailState state) {
    switch (action) {
      case 'clear':
        _confirmClear(context);
    }
  }

  Future<void> _addTier(BuildContext context) async {
    final S l = S.of(context);
    final TextEditingController controller = TextEditingController();
    final String? tierName = await showDialog<String>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tierListAddTier),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l.tierListNameHint),
          onSubmitted: (String value) =>
              Navigator.of(ctx).pop(value.trim()),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l.add),
          ),
        ],
      ),
    );
    if (tierName != null && tierName.isNotEmpty) {
      final String tierKey =
          '${tierName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      await ref
          .read(tierListDetailProvider(widget.tierListId).notifier)
          .addTier(tierKey, tierName, AppColors.brand);
    }
  }

  Future<void> _confirmClear(BuildContext context) async {
    final S l = S.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.tierListClearAll),
        content: Text(l.tierListClearConfirm),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.tierListClearAll),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(tierListDetailProvider(widget.tierListId).notifier)
          .clearAll();
    }
  }

  Future<void> _exportAsImage(
    BuildContext context,
    TierListDetailState state,
  ) async {
    final S l = S.of(context);
    try {
      // Ждём завершения текущего кадра, чтобы export view был отрисован
      await WidgetsBinding.instance.endOfFrame;

      final RenderRepaintBoundary? boundary = _exportKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final List<int> pngBytes = byteData.buffer.asUint8List();

      if (Platform.isAndroid) {
        // Android: сохраняем в галерею через Gal
        final bool hasAccess = await Gal.requestAccess();
        if (!hasAccess) return;
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath =
            '${tempDir.path}/tier_list_${state.tierList.id}.png';
        await File(tempPath).writeAsBytes(pngBytes);
        await Gal.putImage(tempPath, album: 'Tonkatsu Box');
        await File(tempPath).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.tierListImageSaved)),
          );
        }
      } else {
        // Desktop: FilePicker
        final String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: l.tierListExportImage,
          fileName: '${state.tierList.name}.png',
          type: FileType.custom,
          allowedExtensions: <String>['png'],
        );
        if (outputPath == null) return;
        await File(outputPath).writeAsBytes(pngBytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.tierListImageSaved)),
          );
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorPrefix(e.toString()))),
        );
      }
    }
  }
}
