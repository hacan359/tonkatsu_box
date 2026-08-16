import 'dart:math';

import 'package:core/models/collection.dart';
import 'package:core/models/cover_info.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/collection_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../providers/collection_covers_provider.dart';
import '../../providers/collections_provider.dart';
import '../collection_card_shell.dart';
import '../media_type_dots.dart';
import '../media_type_spectrum_bar.dart';

/// Grid card: covers lie in a scattered pile that gathers into a neat
/// deck on hover/focus.
class DeckCollectionCard extends ConsumerWidget {
  const DeckCollectionCard({
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

  /// Shows the collection description (rich mode without a hero image).
  final bool showDescription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<CollectionStats> statsAsync =
        ref.watch(collectionStatsProvider(collection.id));
    // A hidden collection must not even fetch its covers.
    final List<CoverInfo> covers = collection.isHidden
        ? const <CoverInfo>[]
        : ref.watch(collectionCoversProvider(collection.id)).valueOrNull ??
            const <CoverInfo>[];

    final CollectionStats? stats = statsAsync.valueOrNull;
    final List<MediaType> present =
        stats?.presentMediaTypes ?? const <MediaType>[];
    final String? description = collection.description;
    final bool hasDescription =
        showDescription && description != null && description.isNotEmpty;

    final int shown = covers.length > _CoverPile.maxCards
        ? _CoverPile.maxCards
        : covers.length;
    final int hidden = (stats?.total ?? 0) - shown;

    return CollectionCardShell(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onSecondaryTap,
      onFocusChanged: onFocusChanged,
      builder: (BuildContext context, Animation<double> dim) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: collection.isHidden
                      ? const _FanFallbackIcon(Icons.visibility_off_outlined)
                      : AnimatedBuilder(
                          animation: dim,
                          builder: (BuildContext context, Widget? child) =>
                              _CoverPile(
                            covers: covers,
                            hiddenCount: hidden,
                            // Stable per collection, so the scatter doesn't
                            // reshuffle on every rebuild.
                            seed: collection.id,
                            // The dim fades 0.25 -> 0 on hover: 0 = scattered
                            // pile at rest, 1 = gathered neat stack.
                            gather:
                                1 - dim.value / CollectionCardShell.dimOpacity,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        collection.name,
                        style: AppTypography.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasDescription) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 3),
                      _StatsLine(statsAsync: statsAsync),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 96,
                        child: MediaTypeSpectrumBar(
                          counts: stats?.mediaTypeCounts ??
                              const <MediaType, int>{},
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (present.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: MediaTypeDots(types: present, dotSize: 20),
              ),
            AnimatedBuilder(
              animation: dim,
              builder: (BuildContext context, Widget? child) {
                final double t =
                    1 - dim.value / CollectionCardShell.dimOpacity;
                return IgnorePointer(
                  child: ColoredBox(
                    color: AppColors.background.withValues(alpha: 0.18 * t),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CoverPile extends StatelessWidget {
  const _CoverPile({
    required this.covers,
    required this.seed,
    this.hiddenCount = 0,
    this.gather = 0,
  });

  final List<CoverInfo> covers;

  /// Seeds the scatter, so a collection keeps its own arrangement.
  final int seed;

  /// Items beyond the visible cards; badged as "+N" on the top card.
  final int hiddenCount;

  /// 0 = scattered pile, 1 = gathered into a neat stack (hover).
  final double gather;

  static const int maxCards = 8;

  @override
  Widget build(BuildContext context) {
    final int n = covers.length > maxCards ? maxCards : covers.length;
    if (n == 0) return const _FanFallbackIcon(Icons.style_outlined);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final Random rng = Random(seed);
        final double h = c.maxHeight * 0.88;
        final double w = h * 2 / 3;
        // Random nudge/twist read as a dropped pile, not a fanned hand;
        // outer cards may overhang ~8px — the shell clips them on purpose.
        final double wanted = w * 0.60;
        final double maxStep =
            n > 1 ? (c.maxWidth - w * 0.85) / (n - 1) : 0;
        final double step = wanted < maxStep ? wanted : maxStep;

        final List<Offset> nudge = List<Offset>.generate(
          n,
          (int _) => Offset(
            (rng.nextDouble() - 0.5) * w * 0.20,
            (rng.nextDouble() - 0.5) * h * 0.14,
          ),
        );
        final List<double> twist = List<double>.generate(
          n,
          (int _) => (rng.nextDouble() - 0.5) * 0.32,
        );

        Offset offsetFor(int i) {
          final double rel = i - (n - 1) / 2;
          final Offset scattered =
              Offset(rel * step + nudge[i].dx, nudge[i].dy);
          // Gathered: a neat deck with a visible cascade — each card peeks
          // out from under the previous one instead of hiding fully.
          final Offset neat = Offset(rel * w * 0.16, rel * -2);
          return scattered + (neat - scattered) * gather;
        }

        // A bare Stack shrinks to one poster and the parent Column aligns it
        // left; expanding it keeps the pile centered on the full card width.
        return SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < n; i++)
                Transform.translate(
                  offset: offsetFor(i),
                  child: Transform.rotate(
                    angle: twist[i] * (1 - gather),
                    child: _FanPoster(
                      cover: covers[i],
                      width: w,
                      height: h,
                      // The last card paints on top of the pile.
                      badge: i == n - 1 && hiddenCount > 0
                          ? '+$hiddenCount'
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FanPoster extends StatelessWidget {
  const _FanPoster({
    required this.cover,
    required this.width,
    required this.height,
    this.badge,
  });

  final CoverInfo cover;
  final double width;
  final double height;

  /// Dimmed overlay label ("+N") on top of the cover art.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        // A visible frame: reads as the physical edge of a card, and
        // separates dark posters from each other inside the fan.
        border: Border.all(color: AppColors.surfaceBorder, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.55),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (cover.thumbnailUrl != null)
            CachedImage(
              imageType: cover.imageType,
              imageId: cover.coverImageId,
              remoteUrl: cover.thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              placeholder: const SizedBox.shrink(),
              errorWidget: const SizedBox.shrink(),
            ),
          if (badge != null)
            ColoredBox(
              color: AppColors.background.withValues(alpha: 0.6),
              child: Center(
                child: Text(
                  badge!,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FanFallbackIcon extends StatelessWidget {
  const _FanFallbackIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, size: 40, color: AppColors.textTertiary),
    );
  }
}

class _StatsLine extends StatelessWidget {
  const _StatsLine({required this.statsAsync});

  final AsyncValue<CollectionStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      data: (CollectionStats s) => Text(
        S
            .of(context)
            .collectionTileStats(s.total, s.completionPercentFormatted),
        style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      loading: () => const SizedBox(height: 14),
      error: (Object error, StackTrace stack) => Text(
        S.of(context).collectionTileError,
        style: AppTypography.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}
