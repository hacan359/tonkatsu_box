import 'dart:ui';

import 'package:core/models/data_source.dart';

import '../theme/app_assets.dart';

/// Presentation extras for [DataSource].
extension DataSourceUi on DataSource {
  /// Brand color of the source.
  Color get color => Color(colorValue);

  /// Path to the color PNG logo (null when there is no brand asset).
  String? get iconAsset => switch (this) {
        DataSource.igdb => AppAssets.iconIgdbColor,
        DataSource.tmdb => AppAssets.iconTmdbColor,
        DataSource.tvmaze => AppAssets.iconTvMazeColor,
        DataSource.steamGridDb => AppAssets.iconSteamGridDbColor,
        DataSource.vndb => AppAssets.iconVndbColor,
        DataSource.anilist => AppAssets.iconAnilistColor,
        DataSource.mangabaka => AppAssets.iconMangaBakaColor,
        DataSource.mangadex => AppAssets.iconMangaDexColor,
        DataSource.kitsu => AppAssets.iconKitsuColor,
        DataSource.openLibrary => AppAssets.iconOpenLibraryColor,
        DataSource.fantlab => AppAssets.iconFantlabColor,
        DataSource.comicVine => AppAssets.iconComicVineColor,
        DataSource.googleBooks => AppAssets.iconGoogleBooksColor,
        DataSource.hardcover => AppAssets.iconHardcoverColor,
        DataSource.tvdb => AppAssets.iconTvdbColor,
        DataSource.vgMaps => null,
        DataSource.local => null,
      };
}
