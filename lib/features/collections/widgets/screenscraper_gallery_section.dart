import 'package:cached_network_image/cached_network_image.dart';
import 'package:core/api/image_proxy.dart';
import 'package:core/models/image_type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/screenscraper_api.dart';
import '../../../core/selfhost/server_origin.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/platform_features.dart';
import '../../../shared/constants/screenscraper_systemes.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../providers/screenscraper_provider.dart';

/// Display preference for the SS gallery: full set vs only in-game screenshots.
enum ScreenScraperGalleryMode { full, screenshotsOnly }

final RegExp _unsafeInCacheId = RegExp('[^a-z0-9]+');

/// Cache id for one media of one game — unique per type and region, and safe
/// as a file name on the server side of the image proxy.
String ssMediaCacheId({required int gameId, required SsMedia media}) {
  String clean(String value) =>
      value.toLowerCase().replaceAll(_unsafeInCacheId, '_');
  final String format = media.format == null || media.format!.isEmpty
      ? 'png'
      : clean(media.format!);
  return '${gameId}_${clean(media.type)}_${clean(media.region ?? 'none')}'
      '.$format';
}

/// A browser cannot load SS media itself: the host drops its CORS header on an
/// error page, so the whole gallery goes blank whenever SS hiccups.
String ssMediaUrl({required int gameId, required SsMedia media}) {
  if (!kIsWebBuild) return media.url;
  return imageProxyUrl(
    baseUrl: serverBaseUrl(),
    type: ImageType.screenScraperMedia,
    imageId: ssMediaCacheId(gameId: gameId, media: media),
    sourceUrl: media.url,
  );
}

class ScreenScraperGallerySection extends ConsumerWidget {
  const ScreenScraperGallerySection({
    required this.gameName,
    required this.igdbPlatformId,
    this.mode = ScreenScraperGalleryMode.full,
    super.key,
  });

  final String gameName;
  final int? igdbPlatformId;
  final ScreenScraperGalleryMode mode;

  bool get _isSupportedPlatform =>
      igdbPlatformId != null &&
      ScreenScraperSystemes.isSupported(igdbPlatformId!);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isSupportedPlatform || gameName.isEmpty) {
      return const SizedBox.shrink();
    }
    final S l = S.of(context);
    final AsyncValue<SsGame?> async = ref.watch(
      screenScraperGameProvider((
        gameName: gameName,
        igdbPlatformId: igdbPlatformId!,
      )),
    );
    return async.when(
      loading: () => _buildLoading(l),
      error: (Object e, _) => _buildError(l, e.toString()),
      data: (SsGame? game) {
        if (game == null) return const SizedBox.shrink();
        final List<_GalleryEntry> entries = _entriesFromGame(l, game);
        if (entries.isEmpty) return const SizedBox.shrink();
        return _buildGallery(context, l, entries);
      },
    );
  }

  Widget _buildLoading(S l) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l.screenScraperLoading,
            style: AppTypography.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(S l, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        l.screenScraperError(message),
        style: AppTypography.caption.copyWith(color: AppColors.error),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<_GalleryEntry> _entriesFromGame(S l, SsGame game) {
    _GalleryEntry entry(String label, SsMedia m, double aspect) =>
        _GalleryEntry(
          label: label,
          imageUrl: ssMediaUrl(gameId: game.id, media: m),
          aspect: aspect,
        );

    // De-duplicate by type, prefer first occurrence (SS lists best first).
    final Map<String, SsMedia> byType = <String, SsMedia>{};
    for (final SsMedia m in game.medias) {
      byType.putIfAbsent(m.type, () => m);
    }

    if (mode == ScreenScraperGalleryMode.screenshotsOnly) {
      final List<_GalleryEntry> out = <_GalleryEntry>[];
      for (final SsMedia m in game.medias) {
        if (m.type == 'sstitle') {
          out.add(entry(l.screenScraperMediaTitle, m, 1.33));
        } else if (m.type == 'ss') {
          out.add(entry(l.screenScraperMediaScreenshot, m, 1.33));
        }
      }
      return out;
    }

    final List<(String, String, double)> picks = <(String, String, double)>[
      ('box-2D', l.screenScraperMediaBox, 0.72),
      ('box-2D-back', l.screenScraperMediaBoxBack, 0.72),
      ('box-3D', l.screenScraperMediaBox3D, 0.85),
      ('wheel', l.screenScraperMediaWheel, 2.0),
      ('screenmarquee', l.screenScraperMediaMarquee, 2.0),
      ('sstitle', l.screenScraperMediaTitle, 1.33),
      ('ss', l.screenScraperMediaScreenshot, 1.33),
      ('fanart', l.screenScraperMediaFanart, 1.78),
      ('mixrbv2', l.screenScraperMediaMix, 1.33),
    ];
    final List<_GalleryEntry> out = <_GalleryEntry>[];
    for (final (String type, String label, double aspect) in picks) {
      final SsMedia? m = byType[type];
      if (m != null && m.url.isNotEmpty) {
        out.add(entry(label, m, aspect));
      }
    }
    return out;
  }

  Widget _buildGallery(
    BuildContext context,
    S l,
    List<_GalleryEntry> entries,
  ) {
    final bool isScreenshotsOnly = mode == ScreenScraperGalleryMode.screenshotsOnly;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isScreenshotsOnly
                    ? Icons.photo_library_outlined
                    : Icons.image_outlined,
                color: AppColors.brand,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isScreenshotsOnly
                    ? l.screenScraperScreenshotsTitle
                    : l.screenScraperGalleryTitle,
                style: AppTypography.cardTitle
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: _HorizontalScroll(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: entries.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int i) {
                final _GalleryEntry e = entries[i];
                return _Thumbnail(
                  entry: e,
                  onTap: () => _openViewer(context, i, entries),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  void _openViewer(
    BuildContext context,
    int initialIndex,
    List<_GalleryEntry> entries,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.scrim.withAlpha(0xDE),
        pageBuilder: (_, _, _) =>
            _FullscreenViewer(entries: entries, initialIndex: initialIndex),
      ),
    );
  }
}

class _GalleryEntry {
  const _GalleryEntry({
    required this.label,
    required this.imageUrl,
    required this.aspect,
  });
  final String label;
  final String imageUrl;
  final double aspect;
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.entry, required this.onTap});

  final _GalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double width = 120 * entry.aspect.clamp(0.5, 1.5);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: SizedBox(
              width: width,
              height: 110,
              child: CachedNetworkImage(
                imageUrl: entry.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: width,
            child: Text(
              entry.label,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ScrollBehavior + wheel→horizontal translator. Without this, on Windows
/// desktop mouse drag is disabled and the wheel scrolls vertically only.
class _HorizontalScroll extends StatefulWidget {
  const _HorizontalScroll({required this.child});

  final Widget child;

  @override
  State<_HorizontalScroll> createState() => _HorizontalScrollState();
}

class _HorizontalScrollState extends State<_HorizontalScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_controller.hasClients) return;
    final double delta = event.scrollDelta.dy != 0
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    final double target =
        (_controller.offset + delta).clamp(0.0, _controller.position.maxScrollExtent);
    _controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: ScrollConfiguration(
        behavior: const _DesktopDragScrollBehavior(),
        child: PrimaryScrollController(
          controller: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  const _DesktopDragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _FullscreenViewer extends StatefulWidget {
  const _FullscreenViewer({
    required this.entries,
    required this.initialIndex,
  });

  final List<_GalleryEntry> entries;
  final int initialIndex;

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _current = widget.initialIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final int target = (_current + delta).clamp(0, widget.entries.length - 1);
    if (target == _current) return;
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPrev = _current > 0;
    final bool hasNext = _current < widget.entries.length - 1;
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Stack(
            children: <Widget>[
              ScrollConfiguration(
                behavior: const _DesktopDragScrollBehavior(),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: widget.entries.length,
                  onPageChanged: (int i) => setState(() => _current = i),
                  itemBuilder: (BuildContext context, int i) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: CachedNetworkImage(
                            imageUrl: widget.entries[i].imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (hasPrev)
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(left: true, onTap: () => _go(-1)),
                  ),
                ),
              if (hasNext)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _NavArrow(left: false, onTap: () => _go(1)),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(Icons.close, color: AppColors.onOverlay),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.scrim.withAlpha(0x8A),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Text(
                      '${widget.entries[_current].label}   ${_current + 1} / ${widget.entries.length}',
                      style: TextStyle(color: AppColors.onOverlay),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.left, required this.onTap});

  final bool left;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.scrim.withAlpha(0x73),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            left ? Icons.chevron_left : Icons.chevron_right,
            color: AppColors.onOverlay,
            size: 32,
          ),
        ),
      ),
    );
  }
}
