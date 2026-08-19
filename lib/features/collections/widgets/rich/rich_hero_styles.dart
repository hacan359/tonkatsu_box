import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/item_status.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/item_status_ui.dart';
import '../../../../shared/constants/media_type_theme.dart';
import '../../../../shared/constants/rich_hero_style.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typography.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../providers/rich_collections_provider.dart';
import '../hero_image.dart';
import 'default_hero_assets.dart';
import 'hero_back_button.dart';
import 'rich_collection_body.dart';

// Paper-and-ink palette for the comic / sticker styles: those looks need
// fixed physical colors, not theme tokens.
const Color _paper = Color(0xFFF2ECDF);
const Color _ink = Color(0xFF1B1712);
const Color _tape = Color(0xC8E8D48B);
// The white border a printed sticker carries, brighter than the comic paper.
const Color _sticker = Color(0xFFFFFFFF);

const double _kCompactWidth = 720;

/// Under this the sticker column fits one cover per row, and the wrap grows
/// taller than the fixed banner.
const double _kMinStickerColumnsWidth = 180;

bool _isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _kCompactWidth;

/// Hero header of a rich collection, drawn in the style picked in settings.
class RichCollectionHero extends ConsumerStatefulWidget {
  const RichCollectionHero({
    required this.collection,
    required this.items,
    this.heroAbsolutePath,
    this.onBack,
    super.key,
  });

  final Collection collection;
  final List<CollectionItem> items;
  final String? heroAbsolutePath;

  /// When set, the banner carries the screen's back control (the plain title
  /// bar is hidden), drawn in each style's own look.
  final VoidCallback? onBack;

  @override
  ConsumerState<RichCollectionHero> createState() =>
      _RichCollectionHeroState();
}

class _RichCollectionHeroState extends ConsumerState<RichCollectionHero> {
  _HeroStats? _stats;
  List<CollectionItem>? _statsSource;

  /// The screen rebuilds on every keystroke while the item list instance
  /// stays the same, so the O(n) stats pass is keyed on list identity.
  _HeroStats get stats {
    if (_stats == null || !identical(_statsSource, widget.items)) {
      _stats = _HeroStats.fromItems(widget.items);
      _statsSource = widget.items;
    }
    return _stats!;
  }

  @override
  Widget build(BuildContext context) {
    final RichHeroStyle style = ref.watch(richHeroStyleProvider);
    if (style == RichHeroStyle.classic) {
      return RichHeroBanner(
        collection: widget.collection,
        heroAbsolutePath: widget.heroAbsolutePath,
        onBack: widget.onBack,
      );
    }

    final String? path = widget.heroAbsolutePath;
    final String? asset = path == null
        ? defaultHeroAssetForCollection(widget.collection.id)
        : null;
    final ImageProvider? hero = path != null
        ? heroImageProviderFor(path)
        : (asset == null ? null : AssetImage(asset));

    return switch (style) {
      // Unreachable — classic returned above — but keeps the switch total.
      RichHeroStyle.classic => const SizedBox.shrink(),
      RichHeroStyle.comic => _ComicHero(
          collection: widget.collection,
          stats: stats,
          hero: hero,
          onBack: widget.onBack,
        ),
      RichHeroStyle.stickers => _StickerHero(
          collection: widget.collection,
          stats: stats,
          items: widget.items,
          hero: hero,
          onBack: widget.onBack,
        ),
      RichHeroStyle.brutalist => _BrutalistHero(
          collection: widget.collection,
          stats: stats,
          hero: hero,
          onBack: widget.onBack,
        ),
      RichHeroStyle.slats => _SlatsHero(
          collection: widget.collection,
          stats: stats,
          hero: hero,
          onBack: widget.onBack,
        ),
    };
  }
}

/// Active statuses first so the breakdown bar reads progress-to-backlog.
const List<ItemStatus> _statusDisplayOrder = <ItemStatus>[
  ItemStatus.inProgress,
  ItemStatus.replaying,
  ItemStatus.completed,
  ItemStatus.planned,
  ItemStatus.notStarted,
  ItemStatus.dropped,
  ItemStatus.ignored,
];

class _HeroStats {
  _HeroStats._(this.total, this.byStatus, this.byType);

  factory _HeroStats.fromItems(List<CollectionItem> items) {
    final Map<ItemStatus, int> statuses = <ItemStatus, int>{};
    final Map<MediaType, int> types = <MediaType, int>{};
    for (final CollectionItem item in items) {
      statuses[item.status] = (statuses[item.status] ?? 0) + 1;
      types[item.mediaType] = (types[item.mediaType] ?? 0) + 1;
    }
    final List<MapEntry<ItemStatus, int>> byStatus =
        <MapEntry<ItemStatus, int>>[
      for (final ItemStatus s in _statusDisplayOrder)
        if ((statuses[s] ?? 0) > 0) MapEntry<ItemStatus, int>(s, statuses[s]!),
    ];
    final List<MapEntry<MediaType, int>> byType = types.entries.toList()
      ..sort(
        (MapEntry<MediaType, int> a, MapEntry<MediaType, int> b) =>
            b.value.compareTo(a.value),
      );
    return _HeroStats._(items.length, byStatus, byType);
  }

  final int total;
  final List<MapEntry<ItemStatus, int>> byStatus;
  final List<MapEntry<MediaType, int>> byType;

  Color get dominantAccent => byType.isEmpty
      ? AppColors.brand
      : MediaTypeTheme.colorFor(byType.first.key);
}

/// GitHub-language-style proportional bar of the status breakdown.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.stats});

  final _HeroStats stats;

  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: stats.byStatus.isEmpty
            ? ColoredBox(color: AppColors.surfaceLight)
            : Row(
                children: <Widget>[
                  for (final MapEntry<ItemStatus, int> e in stats.byStatus)
                    Expanded(
                      flex: e.value,
                      child: ColoredBox(color: e.key.color),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend({required this.stats});

  final _HeroStats stats;

  @override
  Widget build(BuildContext context) {
    // Dot + count only: labels used to wrap into three lines on phones, and
    // the colors already name the statuses via the proportional bar above.
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final MapEntry<ItemStatus, int> e in stats.byStatus)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                e.value.toString(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Status-only sticker dots: media-type counts already live in the chevron
/// bar above the collection, so the badges never duplicate them.
class _StatusBadges extends StatelessWidget {
  const _StatusBadges({required this.stats, required this.rimColor});

  final _HeroStats stats;

  /// Ink for the comic style, white for the sticker style.
  final Color rimColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (int i = 0; i < stats.byStatus.length; i++)
          Transform.rotate(
            angle: (i.isEven ? 1 : -1) * 0.05,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stats.byStatus[i].key.color,
                shape: BoxShape.circle,
                border: Border.all(color: rimColor, width: 2.5),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _ink.withValues(alpha: 0.35),
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    stats.byStatus[i].key.materialIcon,
                    size: 15,
                    color: _sticker,
                  ),
                  Text(
                    '${stats.byStatus[i].value}',
                    style: AppTypography.caption.copyWith(
                      color: _sticker,
                      fontSize: 10,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One slice of the hero, which is laid out at [fullSize] and cropped.
/// [sliceAxis] is the direction the slices are laid out in.
class _ImageSlice extends StatelessWidget {
  const _ImageSlice({
    required this.provider,
    required this.index,
    required this.sliceCount,
    required this.sliceAxis,
    required this.fullSize,
  });

  final ImageProvider provider;
  final int index;
  final int sliceCount;
  final Axis sliceAxis;
  final Size fullSize;

  @override
  Widget build(BuildContext context) {
    final double t = sliceCount == 1 ? 0 : -1 + 2 * index / (sliceCount - 1);
    final bool sideBySide = sliceAxis == Axis.horizontal;
    return ClipRect(
      child: OverflowBox(
        maxWidth: sideBySide ? fullSize.width : null,
        minWidth: sideBySide ? fullSize.width : null,
        maxHeight: sideBySide ? null : fullSize.height,
        minHeight: sideBySide ? null : fullSize.height,
        alignment: sideBySide ? Alignment(t, 0) : Alignment(0, t),
        child: SizedBox.fromSize(
          size: fullSize,
          child: HeroCoverImage(
            provider: provider,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

// Comic: hero cut into tilted ink-framed panels on halftone paper, caption
// box title, round status badges.

class _ComicHero extends StatelessWidget {
  const _ComicHero({
    required this.collection,
    required this.stats,
    this.hero,
    this.onBack,
  });

  final Collection collection;
  final _HeroStats stats;
  final ImageProvider? hero;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = _isCompact(context);
    final double height = isCompact ? 250 : 330;
    final ImageProvider? image = hero;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: _paper),
          CustomPaint(
            isComplex: true,
            willChange: false,
            painter: _HalftonePainter(color: _ink.withValues(alpha: 0.14)),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: isCompact ? 56 : 64,
            bottom: isCompact ? 60 : 68,
            child: image == null
                ? const SizedBox.shrink()
                : _ComicPanels(hero: image, panels: isCompact ? 3 : 4),
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (onBack != null) ...<Widget>[
                  HeroBackButton(
                    onTap: onBack!,
                    decoration: BoxDecoration(
                      color: _paper,
                      border: Border.all(color: _ink, width: 3),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: _ink, offset: Offset(3, 3)),
                      ],
                    ),
                    iconColor: _ink,
                    angle: 0.03,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Transform.rotate(
                  angle: -0.01,
                  child: Container(
                    constraints: BoxConstraints(
                      // Leave room for the back plate so the row never clips.
                      maxWidth: MediaQuery.sizeOf(context).width * 0.7 -
                          (onBack != null
                              ? HeroBackButton.defaultSize + AppSpacing.sm
                              : 0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ratingStar,
                      border: Border.all(color: _ink, width: 3),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: _ink, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Text(
                      collection.name.toUpperCase(),
                      style: AppTypography.h2.copyWith(
                        color: _ink,
                        fontSize: isCompact ? 18 : 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            bottom: AppSpacing.sm,
            right: AppSpacing.md,
            child: _StatusBadges(stats: stats, rimColor: _ink),
          ),
        ],
      ),
    );
  }
}

class _ComicPanels extends StatelessWidget {
  const _ComicPanels({required this.hero, required this.panels});

  final ImageProvider hero;
  final int panels;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        const double gap = AppSpacing.sm;
        final double panelW = (c.maxWidth - gap * (panels - 1)) / panels;
        return Row(
          children: <Widget>[
            for (int i = 0; i < panels; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: gap),
              Transform.rotate(
                angle: (i.isEven ? -1 : 1) * 0.015,
                child: Container(
                  width: panelW,
                  decoration: BoxDecoration(
                    color: _paper,
                    border: Border.all(color: _ink, width: 3),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: _ink.withValues(alpha: 0.35),
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: _ImageSlice(
                    provider: hero,
                    index: i,
                    sliceCount: panels,
                    sliceAxis: Axis.horizontal,
                    fullSize: Size(c.maxWidth, c.maxHeight),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Sparse dot screen fading toward the middle, like cheap comic print.
class _HalftonePainter extends CustomPainter {
  const _HalftonePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    const double spacing = 14;
    for (double y = 4; y < size.height; y += spacing) {
      for (double x = 4; x < size.width; x += spacing) {
        // Bigger dots toward the edges, none in the center band.
        final double edge =
            (x / size.width - 0.5).abs() + (y / size.height - 0.5).abs();
        final double r = ((edge - 0.35) * 6).clamp(0, 2.4);
        if (r > 0.2) canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalftonePainter oldDelegate) =>
      oldDelegate.color != color;
}

// Stickers: paper page, polaroid hero with tape, item covers as tilted
// stickers, round status stickers.

class _StickerHero extends StatelessWidget {
  const _StickerHero({
    required this.collection,
    required this.stats,
    required this.items,
    this.hero,
    this.onBack,
  });

  final Collection collection;
  final _HeroStats stats;
  final List<CollectionItem> items;
  final ImageProvider? hero;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = _isCompact(context);
    final double height = isCompact ? 260 : 330;
    // On phones the right column is too narrow for cover stickers — the
    // polaroid already carries the image, so only the status dots remain.
    final List<CollectionItem> withCovers = isCompact
        ? const <CollectionItem>[]
        : items
            .where((CollectionItem i) => i.thumbnailUrl != null)
            .take(7)
            .toList();
    const double stickerW = 72;

    final Widget polaroid = Transform.rotate(
      angle: -0.035,
      child: Container(
        width: isCompact ? 190 : 260,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        decoration: BoxDecoration(
          color: _sticker,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: _ink.withValues(alpha: 0.4),
              offset: const Offset(3, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: isCompact ? 120 : 165,
              width: double.infinity,
              child: hero != null
                  ? HeroCoverImage(
                      provider: hero!,
                      alignment: Alignment.center,
                    )
                  : ColoredBox(color: stats.dominantAccent),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                collection.name,
                style: AppTypography.body.copyWith(
                  color: _ink,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: _paper),
          CustomPaint(
            isComplex: true,
            willChange: false,
            painter: _DotGridPainter(color: _ink.withValues(alpha: 0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    polaroid,
                    Positioned(
                      top: -6,
                      left: 24,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Container(width: 64, height: 20, color: _tape),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: isCompact ? AppSpacing.md : AppSpacing.xl),
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      // Below two sticker columns the wrap stacks vertically
                      // past the fixed hero height — drop the covers.
                      final List<CollectionItem> covers =
                          c.maxWidth < _kMinStickerColumnsWidth
                              ? const <CollectionItem>[]
                              : withCovers;
                      // The badges wrap too on very narrow heroes; the
                      // unbounded box plus clip beats an overflow stripe.
                      return ClipRect(
                        child: OverflowBox(
                          maxHeight: double.infinity,
                          child: _StickerHeroSide(
                            covers: covers,
                            stats: stats,
                            stickerW: stickerW,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (onBack != null)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: HeroBackButton(
                onTap: onBack!,
                decoration: BoxDecoration(
                  color: _sticker,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.35),
                      offset: const Offset(2, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                iconColor: _ink,
                angle: -0.08,
              ),
            ),
        ],
      ),
    );
  }
}

class _StickerHeroSide extends StatelessWidget {
  const _StickerHeroSide({
    required this.covers,
    required this.stats,
    required this.stickerW,
  });

  final List<CollectionItem> covers;
  final _HeroStats stats;
  final double stickerW;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (covers.isNotEmpty) ...<Widget>[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (int i = 0; i < covers.length; i++)
                Transform.rotate(
                  angle: ((i * 7) % 5 - 2) * 0.03,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: _sticker,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.35),
                          offset: const Offset(2, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: stickerW,
                        height: stickerW * 1.45,
                        child: CachedImage(
                          imageType: covers[i].imageType,
                          imageId: covers[i].coverImageId,
                          remoteUrl: covers[i].thumbnailUrl ?? '',
                          fit: BoxFit.cover,
                          memCacheWidth: (stickerW * 2).toInt(),
                          placeholder: ColoredBox(
                            color: AppColors.surfaceLight,
                          ),
                          errorWidget: ColoredBox(
                            color: AppColors.surfaceLight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _StatusBadges(stats: stats, rimColor: _sticker),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    const double spacing = 22;
    for (double y = 8; y < size.height; y += spacing) {
      for (double x = 8; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

// Brutalist: loud accent block, hard offset shadows, boxy status counters.

class _BrutalistHero extends StatelessWidget {
  const _BrutalistHero({
    required this.collection,
    required this.stats,
    this.hero,
    this.onBack,
  });

  final Collection collection;
  final _HeroStats stats;
  final ImageProvider? hero;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = _isCompact(context);
    final Color accent = stats.dominantAccent;
    final S l = S.of(context);
    final Color edge = AppColors.textPrimary;

    final Widget titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (onBack != null) ...<Widget>[
              HeroBackButton(
                onTap: onBack!,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: edge, width: 3),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: edge, offset: const Offset(4, 4)),
                  ],
                ),
                iconColor: AppColors.textPrimary,
                size: 42,
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: edge, width: 3),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: edge, offset: const Offset(6, 6)),
                  ],
                ),
                child: Text(
                  collection.name.toUpperCase(),
                  style: AppTypography.h1.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 24 : 40,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (final MapEntry<ItemStatus, int> e in stats.byStatus)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: e.key.color,
                  border: Border.all(color: edge, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: edge, offset: const Offset(3, 3)),
                  ],
                ),
                child: Text(
                  '${e.value} ${e.key.genericLabel(l).toUpperCase()}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent,
        border: Border(bottom: BorderSide(color: edge, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.xl),
        child: (isCompact || hero == null)
            ? titleBlock
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(child: titleBlock),
                  const SizedBox(width: AppSpacing.xl),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: edge, width: 3),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: edge, offset: const Offset(8, 8)),
                      ],
                    ),
                    child: SizedBox(
                      width: 320,
                      height: 180,
                      child: HeroCoverImage(
                        provider: hero!,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Strips: one full-bleed photo cut into panels by slanted gaps, like a
// comic page torn at an angle.

class _SlatsHero extends StatelessWidget {
  const _SlatsHero({
    required this.collection,
    required this.stats,
    this.hero,
    this.onBack,
  });

  final Collection collection;
  final _HeroStats stats;
  final ImageProvider? hero;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool isCompact = _isCompact(context);
    const int strips = 3;
    final double stripH = isCompact ? 56 : 76;
    final double fullHeight = stripH * strips;
    final ImageProvider? image = hero;

    final double sidePadding = isCompact ? AppSpacing.md : AppSpacing.xl;

    // The panels run edge to edge like the other styles; only the text block
    // below keeps the side padding.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (image != null)
          SizedBox(
            width: double.infinity,
            height: fullHeight,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                HeroCoverImage(
                  provider: image,
                  alignment: Alignment.center,
                ),
                CustomPaint(
                  painter: _PanelCutsPainter(
                    color: AppColors.background,
                    cuts: strips - 1,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            AppSpacing.md,
            sidePadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (onBack != null) ...<Widget>[
                    HeroBackButton(
                      onTap: onBack!,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                      iconColor: AppColors.textPrimary,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      collection.name,
                      style: AppTypography.h1.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: isCompact ? 24 : 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.6,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatusBar(stats: stats),
              const SizedBox(height: AppSpacing.sm),
              _StatusLegend(stats: stats),
            ],
          ),
        ),
      ],
    );
  }
}

/// Paints background-colored slanted gaps that cut the hero into panels;
/// straight gaps read as a sliced photo, the diagonals as comic panels.
class _PanelCutsPainter extends CustomPainter {
  const _PanelCutsPainter({required this.color, required this.cuts});

  final Color color;
  final int cuts;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    const double slant = 26;
    // Wedge cut: the gap widens toward the edge the cut rises to, so each
    // panel looks torn off rather than machine-sliced.
    const double gapNarrow = 3;
    const double gapWide = 18;
    for (int i = 1; i <= cuts; i++) {
      final double y = size.height * i / (cuts + 1);
      final bool odd = i.isOdd;
      final double rise = (odd ? 1 : -1) * slant / 2;
      final double leftHalf = (odd ? gapNarrow : gapWide) / 2;
      final double rightHalf = (odd ? gapWide : gapNarrow) / 2;
      final Path path = Path()
        ..moveTo(0, y - rise - leftHalf)
        ..lineTo(size.width, y + rise - rightHalf)
        ..lineTo(size.width, y + rise + rightHalf)
        ..lineTo(0, y - rise + leftHalf)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_PanelCutsPainter oldDelegate) =>
      color != oldDelegate.color || cuts != oldDelegate.cuts;
}
