import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/canvas_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/platform_features.dart';
import '../../../../shared/extensions/snackbar_extension.dart';
import '../../../../shared/models/steamgriddb_image.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_durations.dart';
import '../../providers/canvas_provider.dart';
import '../../providers/steamgriddb_panel_provider.dart';
import '../../providers/vgmaps_panel_provider.dart';
import '../canvas_view.dart';
import '../steamgriddb_panel.dart';
import '../vgmaps_panel.dart';

class ItemDetailCanvasView extends ConsumerWidget {
  const ItemDetailCanvasView({
    required this.collectionId,
    required this.itemId,
    required this.isEditable,
    required this.currentItemName,
    super.key,
  });

  final int? collectionId;
  final int itemId;
  final bool isEditable;
  final String currentItemName;

  ({int? collectionId, int collectionItemId}) get _canvasArg => (
        collectionId: collectionId,
        collectionItemId: itemId,
      );

  void _addImage({
    required WidgetRef ref,
    required BuildContext context,
    required String url,
    required int? width,
    required int? height,
    required double maxWidth,
    required double defaultSize,
    required String snackMessage,
  }) {
    double targetWidth = defaultSize;
    double targetHeight = defaultSize;

    if (width != null && height != null && width > 0 && height > 0) {
      final double aspectRatio = width / height;
      targetWidth = width.toDouble() > maxWidth ? maxWidth : width.toDouble();
      targetHeight = targetWidth / aspectRatio;
    }

    final double centerX =
        CanvasRepository.initialCenterX - targetWidth / 2;
    final double centerY =
        CanvasRepository.initialCenterY - targetHeight / 2;

    ref.read(gameCanvasNotifierProvider(_canvasArg).notifier).addImageItem(
          centerX,
          centerY,
          <String, dynamic>{'url': url},
          width: targetWidth,
          height: targetHeight,
        );

    context.showSnack(snackMessage, type: SnackType.success);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final S l = S.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: CanvasView(
            collectionId: collectionId,
            isEditable: isEditable,
            collectionItemId: itemId,
          ),
        ),
        _AnimatedSidePanel(
          width: 320,
          isOpen: ref.watch(
            steamGridDbPanelProvider(collectionId)
                .select((SteamGridDbPanelState s) => s.isOpen),
          ),
          child: SteamGridDbPanel(
            collectionId: collectionId,
            collectionName: currentItemName,
            onAddImage: (SteamGridDbImage image) => _addImage(
              ref: ref,
              context: context,
              url: image.url,
              width: image.width > 0 ? image.width : null,
              height: image.height > 0 ? image.height : null,
              maxWidth: 300,
              defaultSize: 200,
              snackMessage: l.imageAddedToBoard,
            ),
          ),
        ),
        if (kVgMapsEnabled)
          _AnimatedSidePanel(
            width: 500,
            isOpen: ref.watch(
              vgMapsPanelProvider(collectionId)
                  .select((VgMapsPanelState s) => s.isOpen),
            ),
            child: VgMapsPanel(
              collectionId: collectionId,
              onAddImage: (String url, int? width, int? height) => _addImage(
                ref: ref,
                context: context,
                url: url,
                width: width,
                height: height,
                maxWidth: 400,
                defaultSize: 400,
                snackMessage: l.mapAddedToBoard,
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedSidePanel extends StatelessWidget {
  const _AnimatedSidePanel({
    required this.width,
    required this.isOpen,
    required this.child,
  });

  final double width;
  final bool isOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      width: isOpen ? width : 0,
      curve: Curves.easeInOut,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: isOpen
            ? const Border(left: BorderSide(color: AppColors.surfaceBorder))
            : null,
      ),
      child: isOpen
          ? OverflowBox(
              maxWidth: width,
              alignment: Alignment.centerLeft,
              child: child,
            )
          : const SizedBox.shrink(),
    );
  }
}
