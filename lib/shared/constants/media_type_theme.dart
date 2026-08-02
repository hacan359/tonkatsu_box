
import 'package:core/models/media_type.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Colors and icons that visually distinguish media types.
abstract final class MediaTypeTheme {
  static const Color gameColor = AppColors.gameAccent;

  static const Color movieColor = AppColors.movieAccent;

  static const Color tvShowColor = AppColors.tvShowAccent;

  static const Color animationColor = AppColors.animationAccent;

  static const Color visualNovelColor = AppColors.visualNovelAccent;

  static const Color mangaColor = AppColors.mangaAccent;

  static const Color animeColor = AppColors.animeAccent;

  static const Color bookColor = AppColors.bookAccent;

  static const Color customColor = AppColors.customAccent;

  static IconData iconFor(MediaType type) => switch (type) {
        MediaType.game => Icons.videogame_asset,
        MediaType.movie => Icons.movie,
        MediaType.tvShow => Icons.tv,
        MediaType.animation => Icons.animation,
        MediaType.visualNovel => Icons.menu_book,
        MediaType.manga => Icons.auto_stories,
        MediaType.anime => Icons.play_circle_outline,
        MediaType.book => Icons.menu_book,
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
        MediaType.custom => Icons.dashboard_customize,
      };

  /// Accents ordered around the colour wheel, first repeated at the end to
  /// close a [SweepGradient]. Sorted by hue so a new type places itself.
  static final List<Color> rainbowSweep = () {
    final List<Color> colors = MediaType.values.map(colorFor).toList()
      ..sort(
        (Color a, Color b) => HSVColor.fromColor(a)
            .hue
            .compareTo(HSVColor.fromColor(b).hue),
      );
    return List<Color>.unmodifiable(<Color>[...colors, colors.first]);
  }();

  static Color colorFor(MediaType type) => switch (type) {
        MediaType.game => gameColor,
        MediaType.movie => movieColor,
        MediaType.tvShow => tvShowColor,
        MediaType.animation => animationColor,
        MediaType.visualNovel => visualNovelColor,
        MediaType.manga => mangaColor,
        MediaType.anime => animeColor,
        MediaType.book => bookColor,
        MediaType.custom => customColor,
      };
}
