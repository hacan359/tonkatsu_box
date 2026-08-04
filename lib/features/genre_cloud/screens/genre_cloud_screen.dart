import 'package:core/models/collection_item.dart';
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/media_type_theme.dart';
import '../../../shared/extensions/snackbar_extension.dart';
import '../../../shared/services/png_export_service.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/logo_loader.dart';
import '../../../shared/widgets/draggable_fab.dart';
import '../../../shared/widgets/scrollable_row_with_arrows.dart';
import '../facet.dart';
import '../facet_value.dart';
import '../genre_cloud_aggregate.dart';
import '../providers/genre_cloud_provider.dart';
import '../widgets/genre_cloud_export_view.dart';
import '../widgets/genre_cloud_view.dart';
import '../../../shared/constants/media_type_ui.dart';

/// Preference cloud (genres / platforms / decades) over the whole library,
/// coloured by media type and filtered by the two chip rows.
class GenreCloudScreen extends ConsumerStatefulWidget {
  /// [showTitle] draws the own title strip; pass `false` under a tab that
  /// already names the cloud.
  const GenreCloudScreen({this.showTitle = true, super.key});

  /// Whether to draw the own title strip; see the constructor.
  final bool showTitle;

  @override
  ConsumerState<GenreCloudScreen> createState() => _GenreCloudScreenState();
}

class _GenreCloudScreenState extends ConsumerState<GenreCloudScreen> {
  static final Logger _log = Logger('GenreCloudScreen');

  final GlobalKey _exportKey = GlobalKey();

  // The offscreen export poster re-runs the full cloud layout on every build,
  // so it is mounted only for the duration of an export.
  bool _exporting = false;

  // "Broad strokes" filters: hidden facet dimensions and hidden media types.
  final Set<Facet> _hiddenFacets = <Facet>{};
  final Set<MediaType> _hiddenTypes = <MediaType>{};

  @override
  Widget build(BuildContext context) {
    final S l = S.of(context);
    final AsyncValue<List<CollectionItem>> itemsAsync =
        ref.watch(genreCloudItemsProvider);
    final List<CollectionItem> items =
        itemsAsync.valueOrNull ?? const <CollectionItem>[];

    final Set<Facet> presentF = presentFacets(items);
    final List<Facet> facets = Facet.values.where(presentF.contains).toList();
    final Set<MediaType> presentT = presentMediaTypes(items);
    final List<MediaType> types =
        MediaType.values.where(presentT.contains).toList();

    final Set<Facet> includedFacets =
        presentF.where((Facet f) => !_hiddenFacets.contains(f)).toSet();
    final Set<MediaType> includedTypes =
        presentT.where((MediaType t) => !_hiddenTypes.contains(t)).toSet();

    final List<FacetValue> words = aggregateFacets(
      items,
      includeFacets: includedFacets,
      includeTypes: includedTypes,
    );
    final bool hasWords = words.isNotEmpty;

    return Material(
      color: AppColors.background,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              if (widget.showTitle) _buildHeader(l),
              if (facets.length > 1) _buildFacetLegend(l, facets),
              if (types.length > 1) _buildTypeLegend(l, types),
              Expanded(child: _buildBody(l, itemsAsync, words)),
            ],
          ),
          if (hasWords && _exporting)
            Positioned(
              left: -10000,
              top: -10000,
              child: SizedBox(
                width: kGenreCloudExportWidth,
                height: kGenreCloudExportHeight,
                child: GenreCloudExportView(
                  repaintKey: _exportKey,
                  title: l.genreCloudTitle,
                  words: words,
                ),
              ),
            ),
          if (hasWords)
            DraggableFab(
              mainAction: DraggableFabItem(
                icon: Icons.image_outlined,
                label: l.genreCloudExportImage,
                onTap: () => _exportAsImage(context, words),
              ),
            ),
        ],
      ),
    );
  }

  // Title strip without a back button — this screen is a standalone view
  // reached from the centre nav button, navigated away via the nav bar.
  Widget _buildHeader(S l) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.5),
        ),
      ),
      child: Text(
        l.genreCloudTitle,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFacetLegend(S l, List<Facet> facets) {
    return _ChipRow(
      children: <Widget>[
        for (final Facet facet in facets)
          _LegendChip(
            label: _facetLabel(l, facet),
            hidden: _hiddenFacets.contains(facet),
            onTap: () => setState(() {
              if (!_hiddenFacets.remove(facet)) _hiddenFacets.add(facet);
            }),
          ),
      ],
    );
  }

  Widget _buildTypeLegend(S l, List<MediaType> types) {
    return _ChipRow(
      children: <Widget>[
        for (final MediaType type in types)
          _LegendChip(
            label: type.localizedLabel(l),
            color: MediaTypeTheme.colorFor(type),
            hidden: _hiddenTypes.contains(type),
            onTap: () => setState(() {
              if (!_hiddenTypes.remove(type)) _hiddenTypes.add(type);
            }),
          ),
      ],
    );
  }

  Widget _buildBody(
    S l,
    AsyncValue<List<CollectionItem>> itemsAsync,
    List<FacetValue> words,
  ) {
    return itemsAsync.when(
      loading: () => const Center(child: LogoLoader()),
      error: (Object error, StackTrace stack) => Center(
        child: Text(
          '${l.settingsError}: $error',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
      data: (List<CollectionItem> _) {
        if (words.isEmpty) return _buildEmptyState(l);
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: GenreCloudView(
            words: words,
            resetTooltip: l.genreCloudResetView,
            hiddenLabel: l.genreCloudHidden,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(S l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 64,
              color: AppColors.textTertiary.withAlpha(120),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.genreCloudEmpty,
              style: AppTypography.h3.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l.genreCloudEmptyHint,
              textAlign: TextAlign.center,
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _facetLabel(S l, Facet facet) {
    switch (facet) {
      case Facet.genre:
        return l.genres;
      case Facet.platform:
        return l.facetPlatform;
      case Facet.decade:
        return l.facetDecade;
    }
  }

  Future<void> _exportAsImage(
    BuildContext context,
    List<FacetValue> words,
  ) async {
    final S l = S.of(context);
    // Mount the offscreen export view and wait for it to render.
    setState(() => _exporting = true);
    await WidgetsBinding.instance.endOfFrame;

    final String safeBase = sanitizeFileName(l.genreCloudTitle);
    final String fileName =
        '${safeBase.isEmpty ? 'preference_cloud' : safeBase}.png';

    final BulkExportResult result = await saveBoundaryAsPng(
      repaintKey: _exportKey,
      suggestedFileName: fileName,
      saveDialogTitle: l.genreCloudExportImage,
    );
    if (mounted) setState(() => _exporting = false);
    if (!context.mounted) return;

    switch (result.status) {
      case BulkExportStatus.saved:
        context.showSnack(l.imageSaved, type: SnackType.success);
      case BulkExportStatus.cancelled:
        break;
      case BulkExportStatus.failed:
        _log.warning('Failed to export preference cloud image', result.error);
        context.showSnack(l.genreCloudExportFailed, type: SnackType.error);
    }
  }
}

/// A single scrolling row of legend chips. Wrapping cost the cloud several
/// lines on a phone; a fixed-height row keeps the chrome constant.
class _ChipRow extends StatefulWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  State<_ChipRow> createState() => _ChipRowState();
}

class _ChipRowState extends State<_ChipRow> {
  /// Fits a legend pill and positions the desktop arrows.
  static const double _kRowHeight = 32;

  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Vertical only: the page inset lives in the scroll view's content
      // padding below, so the chips scroll out to the screen edges.
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: SizedBox(
        height: _kRowHeight,
        child: ScrollableRowWithArrows(
          controller: _controller,
          height: _kRowHeight,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              spacing: AppSpacing.sm,
              children: widget.children,
            ),
          ),
        ),
      ),
    );
  }
}

/// Legend pill; tapping hides or shows its dimension. The [color] dot mirrors
/// the cloud's encoding and is omitted by facet chips.
class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.hidden,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool hidden;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (color != null) ...<Widget>[
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: hidden ? AppColors.textTertiary : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    hidden ? AppColors.textTertiary : AppColors.textSecondary,
                decoration:
                    hidden ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
