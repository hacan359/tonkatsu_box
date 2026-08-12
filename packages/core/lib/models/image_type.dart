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

  albumCover('album_covers'),

  customCover('custom_covers');

  const ImageType(this.folder);

  final String folder;
}
