/// Kind of cached image; [folder] is its sub-directory in the cover cache.
enum ImageType {
  gameCover('game_covers'),

  moviePoster('movie_posters'),

  tvShowPoster('tv_show_posters'),

  tvSeasonPoster('tv_season_posters'),

  tvEpisodeStill('tv_episode_stills'),

  canvasImage('canvas_images'),

  mangaCover('manga_covers'),

  vnCover('vn_covers'),

  animeCover('anime_covers'),

  bookCover('book_covers'),

  audioCover('audio_covers'),

  customCover('custom_covers'),

  /// Collection hero backgrounds; on web they live in the server cache
  /// because the browser has no filesystem for the desktop's hero folder.
  collectionHero('collection_heroes');

  const ImageType(this.folder);

  final String folder;
}
