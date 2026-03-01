// Layout канваса с боковыми панелями для CollectionScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/theme/app_colors.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import 'canvas_view.dart';
import 'steamgriddb_panel.dart';
import 'vgmaps_panel.dart';

/// Layout канваса с боковыми панелями SteamGridDB и VGMaps.
///
/// Состоит из [CanvasView] слева и анимированных боковых панелей справа.
/// Панели открываются/закрываются через соответствующие провайдеры.
class CollectionCanvasLayout extends StatelessWidget {
  /// Создаёт [CollectionCanvasLayout].
  const CollectionCanvasLayout({
    required this.collectionId,
    required this.isEditable,
    required this.collectionName,
    required this.onAddSteamGridDbImage,
    required this.onAddVgMapsImage,
    super.key,
  });

  /// ID коллекции.
  final int? collectionId;

  /// Можно ли редактировать канвас.
  final bool isEditable;

  /// Название коллекции (для SteamGridDB поиска).
  final String collectionName;

  /// Callback добавления изображения из SteamGridDB.
  final void Function(SteamGridDbImage image) onAddSteamGridDbImage;

  /// Callback добавления изображения из VGMaps.
  final void Function(String url, int? width, int? height) onAddVgMapsImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: CanvasView(
            collectionId: collectionId,
            isEditable: isEditable,
          ),
        ),
        // Боковая панель SteamGridDB
        _SteamGridDbSidePanel(
          collectionId: collectionId,
          collectionName: collectionName,
          onAddImage: onAddSteamGridDbImage,
        ),
        // Боковая панель VGMaps Browser (Windows only)
        if (kVgMapsEnabled)
          _VgMapsSidePanel(
            collectionId: collectionId,
            onAddImage: onAddVgMapsImage,
          ),
      ],
    );
  }
}

// =============================================================================
// Animated side panels
// =============================================================================

class _SteamGridDbSidePanel extends ConsumerWidget {
  const _SteamGridDbSidePanel({
    required this.collectionId,
    required this.collectionName,
    required this.onAddImage,
  });

  final int? collectionId;
  final String collectionName;
  final void Function(SteamGridDbImage image) onAddImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPanelOpen = ref.watch(
      steamGridDbPanelProvider(collectionId)
          .select((SteamGridDbPanelState s) => s.isOpen),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isPanelOpen ? 320 : 0,
      curve: Curves.easeInOut,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: isPanelOpen
            ? const Border(
                left: BorderSide(
                  color: AppColors.surfaceBorder,
                ),
              )
            : null,
      ),
      child: isPanelOpen
          ? OverflowBox(
              maxWidth: 320,
              alignment: Alignment.centerLeft,
              child: SteamGridDbPanel(
                collectionId: collectionId,
                collectionName: collectionName,
                onAddImage: onAddImage,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _VgMapsSidePanel extends ConsumerWidget {
  const _VgMapsSidePanel({
    required this.collectionId,
    required this.onAddImage,
  });

  final int? collectionId;
  final void Function(String url, int? width, int? height) onAddImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isPanelOpen = ref.watch(
      vgMapsPanelProvider(collectionId)
          .select((VgMapsPanelState s) => s.isOpen),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isPanelOpen ? 500 : 0,
      curve: Curves.easeInOut,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: isPanelOpen
            ? const Border(
                left: BorderSide(
                  color: AppColors.surfaceBorder,
                ),
              )
            : null,
      ),
      child: isPanelOpen
          ? OverflowBox(
              maxWidth: 500,
              alignment: Alignment.centerLeft,
              child: VgMapsPanel(
                collectionId: collectionId,
                onAddImage: onAddImage,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
