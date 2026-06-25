// Offscreen fixed-size preference cloud rendered into a PNG.

import 'package:flutter/material.dart';

import '../../../shared/theme/app_assets.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../facet_value.dart';
import 'genre_cloud_view.dart';

/// Fixed pixel size of the exported poster (logical pixels; the PNG export
/// multiplies this by the pixel ratio for a crisp image).
const double kGenreCloudExportWidth = 1200;

/// Fixed pixel height of the exported poster.
const double kGenreCloudExportHeight = 800;

/// The widget captured by the PNG exporter: a titled, solid-background poster
/// of the cloud with the app credit footer.
class GenreCloudExportView extends StatelessWidget {
  /// Creates a [GenreCloudExportView].
  const GenreCloudExportView({
    required this.repaintKey,
    required this.title,
    required this.words,
    super.key,
  });

  /// Key whose render boundary is captured to a PNG.
  final GlobalKey repaintKey;

  /// Poster heading (collection name or library title).
  final String title;

  /// Facet values to render.
  final List<FacetValue> words;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: kGenreCloudExportWidth,
        height: kGenreCloudExportHeight,
        color: AppColors.background,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GenreCloudView(
                words: words,
                minFontSize: 18,
                maxFontSize: 150,
                interactive: false,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Image.asset(AppAssets.logo, width: 16, height: 16),
                const SizedBox(width: 4),
                Text(
                  'made by Tonkatsu Box',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
