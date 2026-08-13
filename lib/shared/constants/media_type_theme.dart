
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Colors and icons that visually distinguish media types.
abstract final class MediaTypeTheme {
  static Color get gameColor => AppColors.gameAccent;

  static Color get movieColor => AppColors.movieAccent;

  static Color get tvShowColor => AppColors.tvShowAccent;

  static Color get animationColor => AppColors.animationAccent;

  static Color get visualNovelColor => AppColors.visualNovelAccent;

  static Color get mangaColor => AppColors.mangaAccent;

  static Color get animeColor => AppColors.animeAccent;

  static Color get bookColor => AppColors.bookAccent;

  static Color get audioColor => AppColors.audioAccent;

  static Color get customColor => AppColors.customAccent;

  static IconData iconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie,
        MediaType.tvShow => Icons.tv,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
        MediaType.audio => Icons.headphones,
        MediaType.custom => Icons.dashboard_customize,
      };

  /// Placeholder icon for missing covers — outlined variants of [iconFor].
  static IconData placeholderIconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie_outlined,
        MediaType.tvShow => Icons.tv_outlined,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
        MediaType.audio => Icons.headphones_outlined,
        MediaType.custom => Icons.dashboard_customize,
      };

  static AppPalette? _sweepPalette;
  static List<Color> _sweepCache = const <Color>[];

  /// Accents ordered around the colour wheel, first repeated at the end to
  /// close a [SweepGradient]. Sorted by hue so a new type places itself.
  static List<Color> get rainbowSweep {
    // Memoized per palette: callers read this every animation frame, and the
    // hue sort does HSV conversions per comparison.
    if (identical(_sweepPalette, AppColors.palette)) return _sweepCache;
    final List<Color> colors = MediaType.values.map(colorFor).toList()
      ..sort(
        (Color a, Color b) => HSVColor.fromColor(a)
            .hue
            .compareTo(HSVColor.fromColor(b).hue),
      );
    _sweepPalette = AppColors.palette;
    _sweepCache = List<Color>.unmodifiable(<Color>[...colors, colors.first]);
    return _sweepCache;
  }

  static Color colorFor(MediaType type) => switch (type) {
        MediaType.game => gameColor,
        MediaType.movie => movieColor,
        MediaType.tvShow => tvShowColor,
        MediaType.animation => animationColor,
        MediaType.visualNovel => visualNovelColor,
        MediaType.manga => mangaColor,
        MediaType.anime => animeColor,
        MediaType.book => bookColor,
        MediaType.audio => audioColor,
        MediaType.custom => customColor,
      };
}
