import 'package:core/models/anime.dart';
import 'package:core/models/audio_item.dart';
import 'package:core/models/data_source.dart';
import 'package:core/models/game.dart';
import 'package:core/models/media_type.dart';
import 'package:core/models/movie.dart';
import 'package:core/models/tv_show.dart';

/// One entry of a showcase feed, flattened for the card; [media] stays
/// attached so the tap can hand the original model to the details sheet.
class ShowcaseItem {
  const ShowcaseItem({
    required this.media,
    required this.mediaType,
    required this.source,
    required this.externalId,
    required this.title,
    this.posterUrl,
    this.rating,
    this.nextDate,
    this.nextSeason,
    this.nextEpisode,
    this.hasTimeOfDay = false,
    this.formatLabel,
    this.episodes,
    this.durationMinutes,
    this.creator,
    this.genres = const <String>[],
    this.description,
  });

  /// [releaseDate] is the list's full `release_date`; [Movie] keeps the year.
  factory ShowcaseItem.fromMovie(Movie movie, {String? releaseDate}) =>
      ShowcaseItem(
        media: movie,
        mediaType: MediaType.movie,
        source: DataSource.tmdb,
        externalId: movie.tmdbId,
        title: movie.title,
        posterUrl: movie.posterUrl,
        rating: movie.rating,
        nextDate: _parseIsoDate(releaseDate),
        genres: movie.genres ?? const <String>[],
        description: movie.overview,
      );

  /// The next episode comes from a separate details call, so it is passed
  /// in; without it the card shows the show alone.
  factory ShowcaseItem.fromTvShow(
    TvShow show, {
    String? nextAirDate,
    int? nextSeason,
    int? nextEpisode,
  }) {
    final DateTime? nextDate = _parseIsoDate(nextAirDate);
    return ShowcaseItem(
      media: show,
      mediaType: MediaType.tvShow,
      source: DataSource.tmdb,
      externalId: show.tmdbId,
      title: show.title,
      posterUrl: show.posterUrl,
      rating: show.rating,
      nextDate: nextDate,
      nextSeason: nextDate != null ? nextSeason : null,
      nextEpisode: nextDate != null ? nextEpisode : null,
      genres: show.genres ?? const <String>[],
      description: show.overview,
    );
  }

  /// An airing show counts down to its next episode; one not yet out counts
  /// down to its premiere when AniList knows the full start date.
  factory ShowcaseItem.fromAnime(Anime anime, String titleLanguage) {
    final int? airingAt = anime.nextAiringAt;
    final DateTime? nextDate = airingAt != null
        ? DateTime.fromMillisecondsSinceEpoch(airingAt * 1000)
        : _fuzzyDate(anime.startYear, anime.startMonth, anime.startDay);
    return ShowcaseItem(
      media: anime,
      mediaType: MediaType.anime,
      source: anime.source,
      externalId: anime.id,
      title: anime.titleByLanguage(titleLanguage),
      posterUrl: anime.coverUrl,
      rating: anime.rating10,
      nextDate: nextDate,
      nextEpisode: airingAt != null ? anime.nextAiringEpisode : null,
      hasTimeOfDay: airingAt != null,
      formatLabel: anime.formatLabel,
      episodes: anime.episodes,
      durationMinutes: anime.duration,
      creator: anime.studiosString,
      genres: anime.genres ?? const <String>[],
      description: anime.description,
    );
  }

  factory ShowcaseItem.fromGame(Game game) => ShowcaseItem(
        media: game,
        mediaType: MediaType.game,
        source: DataSource.igdb,
        externalId: game.id,
        title: game.name,
        posterUrl: game.coverUrl,
        rating: _igdbRatingTo10(game.rating),
        nextDate: game.releaseDate,
        genres: game.genres ?? const <String>[],
        description: game.summary,
      );

  factory ShowcaseItem.fromAudio(AudioItem audio) => ShowcaseItem(
        media: audio,
        mediaType: MediaType.audio,
        source: audio.source,
        externalId: audio.id,
        title: audio.title,
        posterUrl: audio.coverUrl,
        rating: audio.rating,
        nextDate: _parseIsoDate(audio.firstReleaseDate),
        creator: audio.artistsString,
        genres: audio.genres,
        description: audio.description,
      );

  final Object media;
  final MediaType mediaType;
  final DataSource source;

  /// Id in [source]'s id space; only meaningful together with [source].
  final int externalId;
  final String title;
  final String? posterUrl;

  /// Community rating on a 0-10 scale, or null when the source has none.
  final double? rating;

  /// Next episode, premiere or release; date-only unless [hasTimeOfDay].
  final DateTime? nextDate;
  final int? nextSeason;
  final int? nextEpisode;

  /// AniList gives an airing timestamp; TMDB and IGDB give a calendar day.
  final bool hasTimeOfDay;
  final String? formatLabel;
  final int? episodes;
  final int? durationMinutes;

  /// Studio, artist or publisher — whoever the card credits under the title.
  final String? creator;
  final List<String> genres;
  final String? description;

  // IGDB rates out of 100; every other source here is already out of 10.
  static double? _igdbRatingTo10(double? rating) =>
      rating == null ? null : rating / 10;

  /// Accepts `yyyy-MM-dd` (longer tails ignored); a partial `yyyy` or
  /// `yyyy-MM` is no date to count down to and yields null.
  static DateTime? _parseIsoDate(String? date) {
    if (date == null || date.length < 10) return null;
    return DateTime.tryParse(date.substring(0, 10));
  }

  static DateTime? _fuzzyDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }
}
