import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/platform_features.dart';
import '../../../shared/models/steamgriddb_image.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../providers/steamgriddb_panel_provider.dart';
import '../providers/vgmaps_panel_provider.dart';
import 'canvas_view.dart';
import 'steamgriddb_panel.dart';
import 'vgmaps_panel.dart';

/// [CanvasView] on the left plus animated SteamGridDB/VGMaps side panels;
/// the panels are opened and closed through their respective providers.
class CollectionCanvasLayout extends StatelessWidget {
  const CollectionCanvasLayout({
    required this.collectionId,
    required this.isEditable,
    required this.collectionName,
    required this.onAddSteamGridDbImage,
    required this.onAddVgMapsImage,
    super.key,
  });

  final int? collectionId;

  final bool isEditable;

  /// Used as the initial SteamGridDB search query.
  final String collectionName;

  final void Function(SteamGridDbImage image) onAddSteamGridDbImage;

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
        _SteamGridDbSidePanel(
          collectionId: collectionId,
          collectionName: collectionName,
          onAddImage: onAddSteamGridDbImage,
        ),
        // VGMaps browser panel is Windows only (WebView2).
        if (kVgMapsEnabled)
          _VgMapsSidePanel(
            collectionId: collectionId,
            onAddImage: onAddVgMapsImage,
          ),
      ],
    );
  }
}

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
      duration: AppDurations.normal,
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
      duration: AppDurations.normal,
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
