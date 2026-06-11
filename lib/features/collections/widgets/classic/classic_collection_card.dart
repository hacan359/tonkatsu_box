// Uses [CollectionCardShell] for focus/hover/border, so it is structurally
// identical to the rich card and differs only in the image area content.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/models/cover_info.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../providers/collection_covers_provider.dart';
import '../../providers/collections_provider.dart';
import '../collection_card_overlay.dart';
import '../collection_card_shell.dart';

class ClassicCollectionCard extends ConsumerWidget {
  const ClassicCollectionCard({
    required this.collection,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onFocusChanged,
    this.showDescription = false,
    super.key,
  });

  final Collection collection;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;

  /// Right-click callback; the position is global, ready for showMenu.
  final void Function(Offset globalPosition)? onSecondaryTap;

  final ValueChanged<bool>? onFocusChanged;

  /// Shows the collection description in the overlay (rich mode without hero).
  final bool showDescription;

  static const double _cellRadius = 8;
  static const double _mosaicPadding = 14;
  static const double _cellGap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));
    final AsyncValue<List<CoverInfo>> coversAsync =
        ref.watch(collectionCoversProvider(collection.id));

    return CollectionCardShell(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onFocusChanged: onFocusChanged,
      builder: (BuildContext context, Animation<double> dim) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(_mosaicPadding),
            child: _CoverMosaic(
              covers: coversAsync,
              totalCount: statsAsync.valueOrNull?.total ?? 0,
            ),
          ),
          const CollectionCardBottomScrim(),
          CollectionCardOverlay(
            name: collection.name,
            description: showDescription ? collection.description : null,
            statsAsync: statsAsync,
          ),
          AnimatedBuilder(
            animation: dim,
            builder: (BuildContext context, Widget? child) {
              return IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withAlpha((dim.value * 255).round()),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoverMosaic extends StatelessWidget {
  const _CoverMosaic({required this.covers, required this.totalCount});

  final AsyncValue<List<CoverInfo>> covers;
  final int totalCount;

  static final BorderRadius _cellBorderRadius =
      BorderRadius.circular(ClassicCollectionCard._cellRadius);
  static final BoxDecoration _emptyCellDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        AppColors.surface,
        AppColors.surfaceLight,
      ],
    ),
    borderRadius: _cellBorderRadius,
  );

  @override
  Widget build(BuildContext context) {
    return covers.when(
      data: (List<CoverInfo> data) => _buildGrid(data),
      loading: () => const SizedBox.expand(),
      error: (Object error, StackTrace stack) => _buildEmpty(),
    );
  }

  Widget _buildGrid(List<CoverInfo> data) {
    if (data.isEmpty) return _buildEmpty();

    final int remaining = totalCount - 6;

    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _poster(data, 0)),
              const SizedBox(width: ClassicCollectionCard._cellGap),
              Expanded(child: _poster(data, 1)),
              const SizedBox(width: ClassicCollectionCard._cellGap),
              Expanded(child: _poster(data, 2)),
            ],
          ),
        ),
        const SizedBox(height: ClassicCollectionCard._cellGap),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(child: _poster(data, 3)),
              const SizedBox(width: ClassicCollectionCard._cellGap),
              Expanded(child: _poster(data, 4)),
              const SizedBox(width: ClassicCollectionCard._cellGap),
              Expanded(
                child: remaining > 0
                    ? _counterCell(remaining)
                    : _poster(data, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _poster(List<CoverInfo> data, int index) {
    if (index >= data.length) {
      return _emptyCell();
    }
    return _CoverImage(cover: data[index]);
  }

  Widget _counterCell(int count) {
    if (count <= 0) return _emptyCell();
    return Container(
      decoration: _emptyCellDecoration,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: AppTypography.h3.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _emptyCell() {
    return Container(decoration: _emptyCellDecoration);
  }

  Widget _buildEmpty() {
    return Center(
      child: Icon(
        Icons.folder_rounded,
        color: AppColors.textTertiary.withAlpha(120),
        size: 36,
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.cover});

  final CoverInfo cover;

  static final BorderRadius _borderRadius =
      BorderRadius.circular(ClassicCollectionCard._cellRadius);
  static const Widget _emptyPlaceholder = SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    if (cover.thumbnailUrl == null) {
      return const SizedBox.expand();
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: _borderRadius,
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedImage(
        imageType: cover.imageType,
        imageId: cover.coverImageId,
        remoteUrl: cover.thumbnailUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        placeholder: _emptyPlaceholder,
        errorWidget: _emptyPlaceholder,
      ),
    );
  }
}
