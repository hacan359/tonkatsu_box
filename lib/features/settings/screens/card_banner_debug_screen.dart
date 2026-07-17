// Laboratory: mockups of bottom-banner variants for poster cards, kept in
// release builds (Settings > Laboratory) so future designs can be compared.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/collection.dart';
import '../../../shared/models/collection_item.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../collections/extensions/item_display_name.dart';
import '../../collections/providers/collections_provider.dart';

/// Poster + fake banner content for one demo card.
class _DemoCard {
  const _DemoCard({
    required this.title,
    this.item,
    this.tagName,
    this.tagColor,
    this.statsLabel,
    this.fraction,
    this.apiRating,
    this.year,
    this.statusColor,
    this.statusIcon,
  });

  final String title;
  final CollectionItem? item;
  final String? tagName;
  final Color? tagColor;
  final String? statsLabel;
  final double? fraction;
  final double? apiRating;
  final int? year;
  final Color? statusColor;
  final IconData? statusIcon;

  /// `★7.9 · 2019` — empty string when neither part is known.
  String get metaLine {
    final List<String> parts = <String>[
      if (apiRating != null) '★${apiRating!.toStringAsFixed(1)}',
      if (year != null) '$year',
    ];
    return parts.join(' · ');
  }
}

class CardBannerDebugScreen extends ConsumerStatefulWidget {
  const CardBannerDebugScreen({super.key});

  @override
  ConsumerState<CardBannerDebugScreen> createState() =>
      _CardBannerDebugScreenState();
}

class _CardBannerDebugScreenState extends ConsumerState<CardBannerDebugScreen> {
  int? _selectedCollectionId;

  @override
  Widget build(BuildContext context) {
    final List<Collection> collections =
        ref.watch(collectionsProvider).valueOrNull ?? <Collection>[];
    if (_selectedCollectionId == null && collections.isNotEmpty) {
      _selectedCollectionId = collections.first.id;
    }

    final List<CollectionItem> items = _selectedCollectionId == null
        ? <CollectionItem>[]
        : (ref
                    .watch(collectionItemsNotifierProvider(
                        _selectedCollectionId))
                    .valueOrNull ??
                <CollectionItem>[])
            .where((CollectionItem i) =>
                (i.thumbnailUrl ?? '').isNotEmpty)
            .take(4)
            .toList();

    final List<_DemoCard> demos = _buildDemos(items);

    return Column(
      children: <Widget>[
        const SubScreenTitleBar(title: 'Card Banner Lab'),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              const Text('Posters from: ', style: AppTypography.bodySmall),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: DropdownButton<int>(
                  value: _selectedCollectionId,
                  isExpanded: true,
                  items: collections
                      .map((Collection c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (int? id) =>
                      setState(() => _selectedCollectionId = id),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: <Widget>[
              _VariantSection(
                title: 'B — Solid panel',
                note: 'Hard-edged translucent panel hugging the content. '
                    'Hover: more opaque, full title.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _SolidPanelBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'E — One meta line ( \\ )',
                note: 'Status dot and episodes merged into the rating/date '
                    'line, backslash separators. Tag right.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _InlineSlashBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'F — Dense + status stripe',
                note: 'Status is a colored stripe on the panel edge; single '
                    'title line; rating · date · episodes in one line.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _StatusStripeBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'G — Split meta line',
                note: 'Rating/date left, status + episodes right on the '
                    'same line; tag right of the title.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _SplitMetaBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'H — Label inside progress bar',
                note: 'Episodes label lives inside a taller progress bar '
                    'tinted with the status color.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _ProgressLabelBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'A — Gradient scrim',
                note: 'Netflix-style: soft gradient, title + stats + tag '
                    'inside. Hover: darker gradient, full title.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _GradientBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'C — Frosted glass',
                note: 'Blur + dark tint (heavier to render). Hover: stronger '
                    'blur and tint, full title.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _FrostedBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'D — Stats strip only',
                note: 'Compromise: title stays below the poster (current '
                    'layout), the banner carries only episode stats + tag.',
                demos: demos,
                titleBelowPoster: true,
                builder: (_DemoCard d, bool hovered) =>
                    _StatsStripBanner(demo: d, hovered: hovered),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Four fill levels: overflowing title + everything, completed with stats,
  /// tag without stats, bare title.
  List<_DemoCard> _buildDemos(List<CollectionItem> items) {
    CollectionItem? at(int i) => i < items.length ? items[i] : null;
    String titleAt(int i, String fallback) {
      final CollectionItem? item = at(i);
      return item != null ? ref.displayNameOf(item) : fallback;
    }

    return <_DemoCard>[
      _DemoCard(
        title:
            '${titleAt(0, 'Star Trek')}: The Extended Ultimate Anniversary '
            'Collector Edition of Doom',
        item: at(0),
        tagName: 'weekend',
        tagColor: AppColors.tvShowAccent,
        statsLabel: 'S2 · 12/24',
        fraction: 0.5,
        apiRating: 7.9,
        year: 2019,
        statusColor: AppColors.statusInProgress,
        statusIcon: Icons.play_arrow,
      ),
      _DemoCard(
        title: titleAt(1, 'Dark'),
        item: at(1),
        statsLabel: '24/24',
        fraction: 1.0,
        apiRating: 8.7,
        year: 2017,
        statusColor: AppColors.statusCompleted,
        statusIcon: Icons.check,
      ),
      _DemoCard(
        title: titleAt(2, 'The Wire'),
        item: at(2),
        tagName: 'top',
        tagColor: AppColors.favorite,
        apiRating: 9.3,
        year: 2002,
      ),
      _DemoCard(
        title: titleAt(3, 'Severance'),
        item: at(3),
        year: 2022,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Section + card scaffolding
// ---------------------------------------------------------------------------

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.title,
    required this.note,
    required this.demos,
    required this.builder,
    this.titleBelowPoster = false,
  });

  final String title;
  final String note;
  final List<_DemoCard> demos;
  final Widget Function(_DemoCard demo, bool hovered) builder;
  final bool titleBelowPoster;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            note,
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: demos
                .map((_DemoCard d) => _HoverPosterCard(
                      demo: d,
                      titleBelowPoster: titleBelowPoster,
                      builder: builder,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Poster with hover tracking; the banner is built by [builder].
class _HoverPosterCard extends StatefulWidget {
  const _HoverPosterCard({
    required this.demo,
    required this.builder,
    required this.titleBelowPoster,
  });

  final _DemoCard demo;
  final Widget Function(_DemoCard demo, bool hovered) builder;
  final bool titleBelowPoster;

  @override
  State<_HoverPosterCard> createState() => _HoverPosterCardState();
}

class _HoverPosterCardState extends State<_HoverPosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _posterImage(),
          Align(
            alignment: Alignment.bottomCenter,
            child: widget.builder(widget.demo, _hovered),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: AppSpacing.desktopMaxCardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: AppSpacing.posterAspectRatio,
              child: poster,
            ),
            if (widget.titleBelowPoster) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  widget.demo.title,
                  style: AppTypography.posterTitle,
                  maxLines: _hovered ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.demo.metaLine.isNotEmpty)
                Text(
                  widget.demo.metaLine,
                  style: AppTypography.posterSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _posterImage() {
    final CollectionItem? item = widget.demo.item;
    if (item == null) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          ),
        ),
        child: Center(
          child: Icon(Icons.tv, size: 48, color: Colors.white38),
        ),
      );
    }
    return CachedImage(
      imageType: item.imageType,
      imageId: item.coverImageId,
      remoteUrl: item.thumbnailUrl ?? '',
      fit: BoxFit.cover,
      memCacheWidth: 300,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared banner content (title / stats / tag / progress bar)
// ---------------------------------------------------------------------------

class _BannerContent extends StatelessWidget {
  const _BannerContent({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final bool hasMetaRow = demo.statusColor != null ||
        demo.statsLabel != null ||
        demo.tagName != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AnimatedSize(
          duration: AppDurations.fast,
          alignment: Alignment.bottomLeft,
          child: Text(
            demo.title,
            style: AppTypography.posterTitle.copyWith(
              color: AppColors.textPrimary,
              height: 1.2,
              shadows: const <Shadow>[
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
            maxLines: hovered ? 6 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (demo.metaLine.isNotEmpty) ...<Widget>[
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                if (demo.apiRating != null)
                  TextSpan(
                    text: '★${demo.apiRating!.toStringAsFixed(1)}',
                    style: const TextStyle(color: Color(0xFFFFD700)),
                  ),
                if (demo.apiRating != null && demo.year != null)
                  const TextSpan(text: ' · '),
                if (demo.year != null) TextSpan(text: '${demo.year}'),
              ],
            ),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (hasMetaRow) ...<Widget>[
          const SizedBox(height: 3),
          Row(
            children: <Widget>[
              if (demo.statusColor != null) ...<Widget>[
                _StatusDot(color: demo.statusColor!, icon: demo.statusIcon),
                const SizedBox(width: 4),
              ],
              if (demo.statsLabel != null)
                Expanded(
                  child: Text(
                    demo.statsLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              if (demo.tagName != null)
                _TagChip(name: demo.tagName!, color: demo.tagColor),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, this.icon});

  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon ?? Icons.circle, size: 10, color: Colors.white),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.name, this.color});

  final String name;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 70),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ProgressEdge extends StatelessWidget {
  const _ProgressEdge({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: const ColoredBox(color: AppColors.tvShowAccent),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant A — gradient scrim
// ---------------------------------------------------------------------------

class _GradientBanner extends StatelessWidget {
  const _GradientBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: hovered ? 0.75 : 0.55),
            Colors.black.withValues(alpha: hovered ? 0.95 : 0.85),
          ],
          stops: const <double>[0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
            child: _BannerContent(demo: demo, hovered: hovered),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant B — solid translucent panel
// ---------------------------------------------------------------------------

class _SolidPanelBanner extends StatelessWidget {
  const _SolidPanelBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: _BannerContent(demo: demo, hovered: hovered),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant C — frosted glass
// ---------------------------------------------------------------------------

class _FrostedBanner extends StatelessWidget {
  const _FrostedBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: hovered ? 10 : 5,
          sigmaY: hovered ? 10 : 5,
        ),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          color: Colors.black.withValues(alpha: hovered ? 0.55 : 0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: _BannerContent(demo: demo, hovered: hovered),
              ),
              if (demo.fraction != null)
                _ProgressEdge(fraction: demo.fraction!),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant E — one meta line, backslash separators
// ---------------------------------------------------------------------------

class _InlineSlashBanner extends StatelessWidget {
  const _InlineSlashBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final TextStyle sep = AppTypography.caption.copyWith(
      color: AppColors.textTertiary,
      fontSize: 10,
    );
    final TextStyle base = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
    );

    final List<InlineSpan> spans = <InlineSpan>[];
    void addPart(TextSpan span) {
      if (spans.isNotEmpty) spans.add(TextSpan(text: ' \\ ', style: sep));
      spans.add(span);
    }

    if (demo.apiRating != null) {
      addPart(TextSpan(
        text: '★${demo.apiRating!.toStringAsFixed(1)}',
        style: base.copyWith(color: const Color(0xFFFFD700)),
      ));
    }
    if (demo.year != null) {
      addPart(TextSpan(text: '${demo.year}', style: base));
    }
    if (demo.statsLabel != null) {
      addPart(TextSpan(
        text: demo.statsLabel,
        style: base.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ));
    }

    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedSize(
                  duration: AppDurations.fast,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    demo.title,
                    style: AppTypography.posterTitle.copyWith(height: 1.2),
                    maxLines: hovered ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    if (demo.statusColor != null) ...<Widget>[
                      _StatusDot(
                        color: demo.statusColor!,
                        icon: demo.statusIcon,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: spans),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (demo.tagName != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _TagChip(name: demo.tagName!, color: demo.tagColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant F — dense two-liner with a status stripe on the panel edge
// ---------------------------------------------------------------------------

class _StatusStripeBanner extends StatelessWidget {
  const _StatusStripeBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
    );
    final List<String> parts = <String>[
      if (demo.year != null) '${demo.year}',
      if (demo.statsLabel != null) demo.statsLabel!,
    ];

    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 3,
              color: demo.statusColor ?? Colors.transparent,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 5, 8, 5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AnimatedSize(
                          duration: AppDurations.fast,
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            demo.title,
                            style: AppTypography.posterTitle
                                .copyWith(height: 1.2),
                            maxLines: hovered ? 6 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: <InlineSpan>[
                                    if (demo.apiRating != null)
                                      TextSpan(
                                        text:
                                            '★${demo.apiRating!.toStringAsFixed(1)}'
                                            '${parts.isNotEmpty ? ' · ' : ''}',
                                        style: base.copyWith(
                                          color: const Color(0xFFFFD700),
                                        ),
                                      ),
                                    TextSpan(
                                      text: parts.join(' · '),
                                      style: base,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (demo.tagName != null) ...<Widget>[
                              const SizedBox(width: 4),
                              _TagChip(
                                name: demo.tagName!,
                                color: demo.tagColor,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (demo.fraction != null)
                    _ProgressEdge(fraction: demo.fraction!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant G — split meta line: rating/date left, status + episodes right
// ---------------------------------------------------------------------------

class _SplitMetaBanner extends StatelessWidget {
  const _SplitMetaBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
    );

    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: AnimatedSize(
                        duration: AppDurations.fast,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          demo.title,
                          style: AppTypography.posterTitle
                              .copyWith(height: 1.2),
                          maxLines: hovered ? 6 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (demo.tagName != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _TagChip(name: demo.tagName!, color: demo.tagColor),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            if (demo.apiRating != null)
                              TextSpan(
                                text: '★${demo.apiRating!.toStringAsFixed(1)}'
                                    '${demo.year != null ? ' · ' : ''}',
                                style: base.copyWith(
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            if (demo.year != null)
                              TextSpan(text: '${demo.year}', style: base),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (demo.statusColor != null) ...<Widget>[
                      _StatusDot(
                        color: demo.statusColor!,
                        icon: demo.statusIcon,
                      ),
                      const SizedBox(width: 3),
                    ],
                    if (demo.statsLabel != null)
                      Text(
                        demo.statsLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant H — episodes label inside a taller, status-tinted progress bar
// ---------------------------------------------------------------------------

class _ProgressLabelBanner extends StatelessWidget {
  const _ProgressLabelBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.caption.copyWith(
      color: AppColors.textSecondary,
      fontSize: 10,
    );
    final double? fraction =
        demo.fraction ?? (demo.statusColor != null ? 1.0 : null);
    final Color fillColor = (demo.statusColor ?? AppColors.tvShowAccent)
        .withValues(alpha: demo.fraction != null ? 0.75 : 0.4);

    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AnimatedSize(
                  duration: AppDurations.fast,
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    demo.title,
                    style: AppTypography.posterTitle.copyWith(height: 1.2),
                    maxLines: hovered ? 6 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            if (demo.apiRating != null)
                              TextSpan(
                                text: '★${demo.apiRating!.toStringAsFixed(1)}'
                                    '${demo.year != null ? ' · ' : ''}',
                                style: base.copyWith(
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            if (demo.year != null)
                              TextSpan(text: '${demo.year}', style: base),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (demo.tagName != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _TagChip(name: demo.tagName!, color: demo.tagColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Strip is always rendered so every card keeps the same banner
          // height, with or without status/episodes — mirrors production.
          SizedBox(
            height: 14,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                if (fraction != null)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: fraction,
                    child: ColoredBox(color: fillColor),
                  ),
                if (demo.statsLabel != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        demo.statsLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Variant D — stats strip only (title stays below the poster)
// ---------------------------------------------------------------------------

class _StatsStripBanner extends StatelessWidget {
  const _StatsStripBanner({required this.demo, required this.hovered});

  final _DemoCard demo;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    if (demo.statusColor == null &&
        demo.statsLabel == null &&
        demo.tagName == null) {
      return const SizedBox.shrink();
    }
    return AnimatedContainer(
      duration: AppDurations.fast,
      color: Colors.black.withValues(alpha: hovered ? 0.8 : 0.55),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: <Widget>[
                if (demo.statusColor != null) ...<Widget>[
                  _StatusDot(
                    color: demo.statusColor!,
                    icon: demo.statusIcon,
                  ),
                  const SizedBox(width: 4),
                ],
                if (demo.statsLabel != null) ...<Widget>[
                  const Icon(
                    Icons.live_tv_outlined,
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      demo.statsLabel!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  const Spacer(),
                if (demo.tagName != null)
                  _TagChip(name: demo.tagName!, color: demo.tagColor),
              ],
            ),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}
