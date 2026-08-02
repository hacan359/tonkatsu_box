import 'package:core/models/collection.dart';
import 'package:core/models/collection_item.dart';
import 'package:core/models/data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_durations.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../shared/widgets/source_logo.dart';
import '../../../shared/widgets/sub_screen_title_bar.dart';
import '../../collections/extensions/item_display_name.dart';
import '../../collections/providers/collections_provider.dart';

/// Poster + fake banner content for one demo card.
class _DemoCard {
  const _DemoCard({
    required this.title,
    required this.source,
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
  final DataSource source;
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
              Text('Posters from: ', style: AppTypography.bodySmall),
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
              const _VotePrompt(),
              _VariantSection(
                title: 'D — Stats strip only',
                note: 'Current layout: title and meta line below the poster, '
                    'the strip carries status and tag on the left and the '
                    'episode count on the right.',
                demos: demos,
                titleBelowPoster: true,
                builder: (_DemoCard d, bool hovered) =>
                    _StatsStripBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'F — Dense + status stripe',
                note: 'Status is a colored stripe on the panel edge; single '
                    'title line; source, rating and date left, episode count '
                    'right.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _StatusStripeBanner(demo: d, hovered: hovered),
              ),
              _VariantSection(
                title: 'G — Split meta line',
                note: 'Source, rating and date left, status and episode count '
                    'right on the same line; tag right of the title.',
                demos: demos,
                builder: (_DemoCard d, bool hovered) =>
                    _SplitMetaBanner(demo: d, hovered: hovered),
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
        source: DataSource.tmdb,
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
        source: DataSource.anilist,
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
        source: DataSource.igdb,
        tagName: 'top',
        tagColor: AppColors.favorite,
        apiRating: 9.3,
        year: 2002,
      ),
      _DemoCard(
        title: titleAt(3, 'Severance'),
        item: at(3),
        source: DataSource.mangadex,
        year: 2022,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Section + card scaffolding
// ---------------------------------------------------------------------------

/// Tappable banner inviting the user to vote for their favourite design on the
/// project Discord channel.
class _VotePrompt extends StatelessWidget {
  const _VotePrompt();

  static final Uri _discordUri = Uri.parse(
    'https://discord.com/channels/1483101784351313994/1483105825835716658',
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Material(
        color: AppColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () =>
              launchUrl(_discordUri, mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                const Icon(Icons.how_to_vote, color: AppColors.brand),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Vote for your favourite design',
                        style: AppTypography.h3,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Pick the banner variant you like best and cast your '
                        'vote on our Discord channel.',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: AppColors.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              _MetaLine(
                source: widget.demo.source,
                span: TextSpan(
                  text: widget.demo.metaLine,
                  style: AppTypography.posterSubtitle,
                ),
                fontSize: AppTypography.posterSubtitle.fontSize ?? 11,
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

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.source,
    required this.span,
    required this.fontSize,
  });

  final DataSource source;
  final InlineSpan span;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SourceLogo(source: source, size: fontSize * 1.1),
        SizedBox(width: fontSize * 0.3),
        Expanded(
          child: Text.rich(span, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _EpisodeCount extends StatelessWidget {
  const _EpisodeCount({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
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

    // A left border (not a stretched sibling) gives the full-height stripe
    // without an IntrinsicHeight — IntrinsicHeight fights the AnimatedSize
    // title and overflows while it animates.
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: hovered ? 0.85 : 0.6),
        border: Border(
          left: BorderSide(
            color: demo.statusColor ?? Colors.transparent,
            width: 3,
          ),
        ),
      ),
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
                    style: AppTypography.posterTitle.copyWith(height: 1.2),
                    maxLines: hovered ? 6 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetaLine(
                        source: demo.source,
                        fontSize: base.fontSize ?? 10,
                        span: TextSpan(
                          children: <InlineSpan>[
                            if (demo.apiRating != null)
                              TextSpan(
                                text:
                                    '★${demo.apiRating!.toStringAsFixed(1)}'
                                    '${demo.year != null ? ' · ' : ''}',
                                style: base.copyWith(
                                  color: const Color(0xFFFFD700),
                                ),
                              ),
                            if (demo.year != null)
                              TextSpan(text: '${demo.year}', style: base),
                          ],
                        ),
                      ),
                    ),
                    if (demo.tagName != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _TagChip(
                        name: demo.tagName!,
                        color: demo.tagColor,
                      ),
                    ],
                    if (demo.statsLabel != null) ...<Widget>[
                      const SizedBox(width: 4),
                      _EpisodeCount(label: demo.statsLabel!),
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
                      child: _MetaLine(
                        source: demo.source,
                        fontSize: base.fontSize ?? 10,
                        span: TextSpan(
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
                      _EpisodeCount(label: demo.statsLabel!),
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
            // Status and tag left, episode count right — the split the
            // Discord vote asked for.
            child: Row(
              children: <Widget>[
                if (demo.statusColor != null) ...<Widget>[
                  _StatusDot(
                    color: demo.statusColor!,
                    icon: demo.statusIcon,
                  ),
                  const SizedBox(width: 4),
                ],
                // The tag takes the free space so the count lands on the right
                // edge; a Spacer would split it with the tag's flex.
                Expanded(
                  child: demo.tagName != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: _TagChip(
                            name: demo.tagName!,
                            color: demo.tagColor,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (demo.statsLabel != null)
                  _EpisodeCount(label: demo.statsLabel!),
              ],
            ),
          ),
          if (demo.fraction != null) _ProgressEdge(fraction: demo.fraction!),
        ],
      ),
    );
  }
}
